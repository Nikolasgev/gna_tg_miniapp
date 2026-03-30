#!/usr/bin/env python3
"""
Скрипт для удаления дубликатов товаров в production базе данных.

Удаляет более поздние дубликаты, оставляя самые ранние записи.
"""
import asyncio
import os
import sys
from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker
from sqlalchemy import select, func, delete
from app.models.product import Product

async def remove_duplicates():
    """Удалить дубликаты товаров."""
    production_db_url = os.getenv('DATABASE_URL')
    
    if not production_db_url:
        print("❌ Ошибка: DATABASE_URL не установлен")
        print()
        print("Установите переменную окружения DATABASE_URL:")
        print("  export DATABASE_URL='postgresql://user:password@host:5432/dbname'")
        sys.exit(1)
    
    # Конвертируем postgresql:// в postgresql+asyncpg:// если нужно
    if not production_db_url.startswith('postgresql+asyncpg://'):
        if production_db_url.startswith('postgresql://'):
            production_db_url = production_db_url.replace('postgresql://', 'postgresql+asyncpg://', 1)
        else:
            print("❌ Ошибка: DATABASE_URL должен начинаться с 'postgresql://' или 'postgresql+asyncpg://'")
            sys.exit(1)
    
    print("=" * 50)
    print("🗑️  УДАЛЕНИЕ ДУБЛИКАТОВ ТОВАРОВ")
    print("=" * 50)
    print()
    
    # Подключаемся к production БД
    print(f"🔌 Подключение к production БД...")
    engine = create_async_engine(production_db_url, echo=False)
    async_session = async_sessionmaker(engine, expire_on_commit=False)
    
    async with async_session() as session:
        # Находим дубликаты по title и business_id
        result = await session.execute(
            select(Product.title, Product.business_id, func.count(Product.id).label('count'))
            .group_by(Product.title, Product.business_id)
            .having(func.count(Product.id) > 1)
        )
        duplicates = result.all()
        
        if not duplicates:
            print("✅ Дубликаты не найдены")
            return
        
        print(f"📦 Найдено {len(duplicates)} групп дубликатов")
        print()
        
        deleted_count = 0
        
        # Для каждой группы дубликатов удаляем все кроме самого раннего
        for dup in duplicates:
            # Получаем все товары с таким названием
            result = await session.execute(
                select(Product)
                .where(Product.title == dup.title)
                .where(Product.business_id == dup.business_id)
                .order_by(Product.created_at)
            )
            products = result.scalars().all()
            
            if len(products) > 1:
                # Оставляем первый (самый ранний), удаляем остальные
                to_delete = products[1:]
                delete_ids = [p.id for p in to_delete]
                
                # Удаляем связи с категориями
                from sqlalchemy import delete as sql_delete
                from app.models.product_category import product_categories
                
                for product_id in delete_ids:
                    await session.execute(
                        sql_delete(product_categories).where(
                            product_categories.c.product_id == product_id
                        )
                    )
                
                # Удаляем товары
                await session.execute(
                    sql_delete(Product).where(Product.id.in_(delete_ids))
                )
                
                deleted_count += len(to_delete)
                print(f"✅ Удалено {len(to_delete)} дубликатов товара '{dup.title}'")
        
        await session.commit()
        
        print()
        print("=" * 50)
        print(f"✅ УДАЛЕНО ДУБЛИКАТОВ: {deleted_count}")
        print("=" * 50)
        
        # Проверяем результат
        result = await session.execute(
            select(func.count(Product.id))
            .where(Product.is_active == True)
        )
        total_count = result.scalar()
        print(f"📦 Всего активных товаров: {total_count}")
        print("=" * 50)
    
    await engine.dispose()


if __name__ == '__main__':
    asyncio.run(remove_duplicates())

