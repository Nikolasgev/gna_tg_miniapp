#!/usr/bin/env python3
"""
Скрипт для переноса товаров из локальной базы данных в production.

Использование:
    python migrate_products_to_production.py

Требуется:
    - Локальная БД должна быть доступна (через docker-compose или локальный PostgreSQL)
    - DATABASE_URL для production должен быть установлен в переменных окружения
    - Или передать через аргументы командной строки
"""
import asyncio
import os
import sys
from decimal import Decimal
from datetime import datetime
from typing import List, Dict, Any
import uuid

from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker
from sqlalchemy import select
from sqlalchemy.orm import selectinload

# Добавляем путь к app
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from app.models.product import Product
from app.models.business import Business
from app.models.category import Category
from app.models.product_category import product_categories


async def get_local_products(local_db_url: str) -> List[Dict[str, Any]]:
    """Получить все товары из локальной базы данных."""
    print(f"🔌 Подключение к локальной БД: {local_db_url.split('@')[1] if '@' in local_db_url else 'localhost'}")
    
    engine = create_async_engine(local_db_url, echo=False)
    async_session = async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)
    
    async with async_session() as session:
        # Получаем все активные товары с категориями
        stmt = select(Product).options(
            selectinload(Product.categories),
            selectinload(Product.business)
        ).where(Product.is_active == True)
        
        result = await session.execute(stmt)
        products = result.scalars().all()
        
        products_data = []
        for product in products:
            # Получаем ID категорий
            category_ids = [cat.id for cat in product.categories]
            
            # Получаем business_slug
            business_slug = product.business.slug if product.business else None
            
            product_data = {
                'id': str(product.id),
                'business_id': str(product.business_id),
                'business_slug': business_slug,
                'title': product.title,
                'description': product.description,
                'price': float(product.price),
                'currency': product.currency,
                'sku': product.sku,
                'image_url': product.image_url,
                'variations': product.variations,
                'discount_percentage': float(product.discount_percentage) if product.discount_percentage else None,
                'discount_price': float(product.discount_price) if product.discount_price else None,
                'discount_valid_from': product.discount_valid_from.isoformat() if product.discount_valid_from else None,
                'discount_valid_until': product.discount_valid_until.isoformat() if product.discount_valid_until else None,
                'stock_quantity': product.stock_quantity,
                'is_active': product.is_active,
                'category_ids': [str(cat_id) for cat_id in category_ids],
                'created_at': product.created_at.isoformat() if product.created_at else None,
            }
            products_data.append(product_data)
        
        print(f"✅ Найдено {len(products_data)} товаров в локальной БД")
        return products_data


async def migrate_products_to_production(
    local_db_url: str,
    production_db_url: str,
    business_slug: str = 'default-business'
):
    """Перенести товары из локальной БД в production."""
    print("🚀 Начинаю миграцию товаров...")
    print(f"📦 Локальная БД: {local_db_url.split('@')[1] if '@' in local_db_url else 'localhost'}")
    print(f"☁️  Production БД: {production_db_url.split('@')[1] if '@' in production_db_url else 'production'}")
    print()
    
    # Получаем товары из локальной БД
    products_data = await get_local_products(local_db_url)
    
    if not products_data:
        print("❌ Товары не найдены в локальной БД")
        return
    
    # Подключаемся к production БД
    print(f"🔌 Подключение к production БД...")
    engine = create_async_engine(production_db_url, echo=False)
    async_session = async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)
    
    async with async_session() as session:
        # Получаем business_id из production БД
        stmt = select(Business).where(Business.slug == business_slug)
        result = await session.execute(stmt)
        business = result.scalar_one_or_none()
        
        if not business:
            print(f"❌ Бизнес с slug '{business_slug}' не найден в production БД")
            print("   Создайте бизнес сначала или укажите правильный slug")
            return
        
        production_business_id = business.id
        print(f"✅ Найден бизнес: {business.name} (ID: {production_business_id})")
        print()
        
        # Получаем все категории из production БД для маппинга
        stmt = select(Category).where(Category.business_id == production_business_id)
        result = await session.execute(stmt)
        production_categories = {cat.id: cat for cat in result.scalars().all()}
        print(f"✅ Найдено {len(production_categories)} категорий в production БД")
        print()
        
        # Создаем товары в production БД
        created_count = 0
        skipped_count = 0
        error_count = 0
        
        for product_data in products_data:
            try:
                # Проверяем, существует ли товар с таким ID
                existing_product = await session.get(Product, uuid.UUID(product_data['id']))
                if existing_product:
                    print(f"⏭️  Товар '{product_data['title']}' уже существует, пропускаю...")
                    skipped_count += 1
                    continue
                
                # Создаем новый товар
                new_product = Product(
                    id=uuid.UUID(product_data['id']),
                    business_id=production_business_id,
                    title=product_data['title'],
                    description=product_data['description'],
                    price=Decimal(str(product_data['price'])),
                    currency=product_data['currency'],
                    sku=product_data['sku'],
                    image_url=product_data['image_url'],
                    variations=product_data['variations'],
                    discount_percentage=Decimal(str(product_data['discount_percentage'])) if product_data['discount_percentage'] else None,
                    discount_price=Decimal(str(product_data['discount_price'])) if product_data['discount_price'] else None,
                    discount_valid_from=datetime.fromisoformat(product_data['discount_valid_from']) if product_data['discount_valid_from'] else None,
                    discount_valid_until=datetime.fromisoformat(product_data['discount_valid_until']) if product_data['discount_valid_until'] else None,
                    stock_quantity=product_data['stock_quantity'],
                    is_active=product_data['is_active'],
                )
                
                # Устанавливаем created_at если есть
                if product_data['created_at']:
                    new_product.created_at = datetime.fromisoformat(product_data['created_at'])
                
                session.add(new_product)
                
                # Добавляем категории (если они существуют в production БД)
                if product_data['category_ids']:
                    for category_id_str in product_data['category_ids']:
                        try:
                            category_id = uuid.UUID(category_id_str)
                            # Проверяем, существует ли категория в production БД
                            # Если нет, пропускаем (можно будет добавить вручную)
                            if category_id in production_categories:
                                new_product.categories.append(production_categories[category_id])
                        except (ValueError, KeyError):
                            pass  # Пропускаем несуществующие категории
                
                await session.commit()
                created_count += 1
                print(f"✅ Создан товар: {product_data['title']}")
                
            except Exception as e:
                await session.rollback()
                error_count += 1
                print(f"❌ Ошибка при создании товара '{product_data['title']}': {e}")
        
        print()
        print("=" * 50)
        print(f"📊 Итоги миграции:")
        print(f"   ✅ Создано: {created_count}")
        print(f"   ⏭️  Пропущено: {skipped_count}")
        print(f"   ❌ Ошибок: {error_count}")
        print(f"   📦 Всего обработано: {len(products_data)}")
        print("=" * 50)
    
    await engine.dispose()


async def main():
    """Главная функция."""
    # URL локальной БД (из docker-compose.yml)
    local_db_url = os.getenv(
        'LOCAL_DATABASE_URL',
        'postgresql+asyncpg://postgres:postgres@localhost:5432/tg_store_db'
    )
    
    # URL production БД (из переменных окружения Railway)
    production_db_url = os.getenv('DATABASE_URL')
    
    if not production_db_url:
        print("❌ Ошибка: DATABASE_URL не установлен")
        print()
        print("Установите переменную окружения DATABASE_URL:")
        print("  export DATABASE_URL='postgresql+asyncpg://user:password@host:5432/dbname'")
        print()
        print("Или передайте через аргументы:")
        print("  python migrate_products_to_production.py <production_db_url>")
        sys.exit(1)
    
    # Проверяем, что production_db_url использует asyncpg
    if not production_db_url.startswith('postgresql+asyncpg://'):
        if production_db_url.startswith('postgresql://'):
            production_db_url = production_db_url.replace('postgresql://', 'postgresql+asyncpg://', 1)
        else:
            print("❌ Ошибка: DATABASE_URL должен начинаться с 'postgresql://' или 'postgresql+asyncpg://'")
            sys.exit(1)
    
    business_slug = os.getenv('BUSINESS_SLUG', 'default-business')
    
    print("=" * 50)
    print("🔄 МИГРАЦИЯ ТОВАРОВ В PRODUCTION")
    print("=" * 50)
    print()
    
    await migrate_products_to_production(local_db_url, production_db_url, business_slug)


if __name__ == '__main__':
    asyncio.run(main())

