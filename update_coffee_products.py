#!/usr/bin/env python3
"""
Скрипт для обновления товаров кофейни в production из локальной базы.

1. Удаляет товары косметики из production
2. Обновляет товары кофейни из локальной базы (со скидками и картинками)
"""
import asyncio
import os
import sys
from decimal import Decimal
from datetime import datetime
from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker
from sqlalchemy import select, delete
from sqlalchemy.orm import selectinload
from app.models.product import Product
from app.models.business import Business
from app.models.product_category import product_categories

async def update_coffee_products():
    """Обновить товары кофейни в production."""
    local_db_url = os.getenv(
        'LOCAL_DATABASE_URL',
        'postgresql+asyncpg://postgres:postgres@localhost:5432/tg_store_db'
    )
    
    production_db_url = os.getenv('DATABASE_URL')
    
    if not production_db_url:
        print("❌ Ошибка: DATABASE_URL не установлен")
        sys.exit(1)
    
    # Конвертируем postgresql:// в postgresql+asyncpg:// если нужно
    if not production_db_url.startswith('postgresql+asyncpg://'):
        if production_db_url.startswith('postgresql://'):
            production_db_url = production_db_url.replace('postgresql://', 'postgresql+asyncpg://', 1)
    
    print("=" * 50)
    print("☕ ОБНОВЛЕНИЕ ТОВАРОВ КОФЕЙНИ")
    print("=" * 50)
    print()
    
    # Подключаемся к локальной БД
    print("🔌 Подключение к локальной БД...")
    local_engine = create_async_engine(local_db_url, echo=False)
    local_session = async_sessionmaker(local_engine, expire_on_commit=False)
    
    # Подключаемся к production БД
    print("🔌 Подключение к production БД...")
    prod_engine = create_async_engine(production_db_url, echo=False)
    prod_session = async_sessionmaker(prod_engine, expire_on_commit=False)
    
    async with local_session() as local_db, prod_session() as prod_db:
        # Получаем бизнес из локальной БД
        stmt = select(Business).where(Business.slug == 'default-business')
        result = await local_db.execute(stmt)
        local_business = result.scalar_one_or_none()
        
        if not local_business:
            print("❌ Бизнес не найден в локальной БД")
            return
        
        # Получаем товары кофейни из локальной БД (исключаем косметику)
        stmt = select(Product).options(
            selectinload(Product.categories)
        ).where(
            Product.business_id == local_business.id,
            Product.is_active == True,
            ~Product.title.like('%MASK%'),
            ~Product.title.like('%KBYO%'),
            ~Product.title.like('%KLOR%')
        ).order_by(Product.created_at)
        
        result = await local_db.execute(stmt)
        local_products = result.scalars().all()
        
        print(f"✅ Найдено {len(local_products)} товаров кофейни в локальной БД")
        print()
        
        # Получаем бизнес из production БД
        stmt = select(Business).where(Business.slug == 'default-business')
        result = await prod_db.execute(stmt)
        prod_business = result.scalar_one_or_none()
        
        if not prod_business:
            print("❌ Бизнес не найден в production БД")
            return
        
        # Удаляем товары косметики из production
        print("🗑️  Удаление товаров косметики...")
        stmt = select(Product).where(
            Product.business_id == prod_business.id,
            (
                Product.title.like('%MASK%') |
                Product.title.like('%KBYO%') |
                Product.title.like('%KLOR%')
            )
        )
        result = await prod_db.execute(stmt)
        cosmetic_products = result.scalars().all()
        
        if cosmetic_products:
            cosmetic_ids = [p.id for p in cosmetic_products]
            
            # Удаляем связи с категориями
            from sqlalchemy import delete as sql_delete
            for product_id in cosmetic_ids:
                await prod_db.execute(
                    sql_delete(product_categories).where(
                        product_categories.c.product_id == product_id
                    )
                )
            
            # Удаляем товары
            await prod_db.execute(
                sql_delete(Product).where(Product.id.in_(cosmetic_ids))
            )
            print(f"✅ Удалено {len(cosmetic_products)} товаров косметики")
        else:
            print("ℹ️  Товары косметики не найдены")
        
        print()
        
        # Обновляем/создаем товары кофейни
        updated_count = 0
        created_count = 0
        
        for local_product in local_products:
            # Ищем товар в production по title и business_id
            stmt = select(Product).where(
                Product.business_id == prod_business.id,
                Product.title == local_product.title
            )
            result = await prod_db.execute(stmt)
            prod_product = result.scalar_one_or_none()
            
            if prod_product:
                # Обновляем существующий товар
                prod_product.description = local_product.description
                prod_product.price = local_product.price
                prod_product.currency = local_product.currency
                prod_product.sku = local_product.sku
                prod_product.image_url = local_product.image_url
                prod_product.variations = local_product.variations
                prod_product.discount_percentage = local_product.discount_percentage
                prod_product.discount_price = local_product.discount_price
                prod_product.discount_valid_from = local_product.discount_valid_from
                prod_product.discount_valid_until = local_product.discount_valid_until
                prod_product.stock_quantity = local_product.stock_quantity
                prod_product.is_active = local_product.is_active
                
                updated_count += 1
                print(f"✅ Обновлен: {local_product.title}")
            else:
                # Создаем новый товар
                new_product = Product(
                    id=local_product.id,
                    business_id=prod_business.id,
                    title=local_product.title,
                    description=local_product.description,
                    price=local_product.price,
                    currency=local_product.currency,
                    sku=local_product.sku,
                    image_url=local_product.image_url,
                    variations=local_product.variations,
                    discount_percentage=local_product.discount_percentage,
                    discount_price=local_product.discount_price,
                    discount_valid_from=local_product.discount_valid_from,
                    discount_valid_until=local_product.discount_valid_until,
                    stock_quantity=local_product.stock_quantity,
                    is_active=local_product.is_active,
                    created_at=local_product.created_at,
                )
                prod_db.add(new_product)
                created_count += 1
                print(f"✅ Создан: {local_product.title}")
        
        await prod_db.commit()
        
        print()
        print("=" * 50)
        print(f"✅ ОБНОВЛЕНО: {updated_count}")
        print(f"✅ СОЗДАНО: {created_count}")
        print(f"📦 ВСЕГО ТОВАРОВ КОФЕЙНИ: {len(local_products)}")
        print("=" * 50)
    
    await local_engine.dispose()
    await prod_engine.dispose()


if __name__ == '__main__':
    asyncio.run(update_coffee_products())

