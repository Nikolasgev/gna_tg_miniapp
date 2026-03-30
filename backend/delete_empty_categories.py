"""Скрипт для удаления пустых категорий."""
import asyncio
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy import select, func

from app.config import settings
from app.services.business_service import BusinessService
from app.services.category_service import CategoryService
from app.models.category import Category
from app.models.product_category import product_categories


async def delete_empty_categories():
    """Удалить категории, у которых нет товаров."""
    
    business_slug = "hair-cosmetics"
    
    # Создаем подключение к БД
    engine = create_async_engine(settings.database_url, echo=False)
    async_session = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)
    
    async with async_session() as db:
        business_service = BusinessService(db)
        category_service = CategoryService(db)
        
        # Получаем бизнес
        business = await business_service.get_by_slug(business_slug)
        if not business:
            print(f"❌ Бизнес '{business_slug}' не найден!")
            await engine.dispose()
            return
        
        print(f"✅ Найден бизнес: {business.name} (slug: {business.slug})")
        
        # Получаем все категории бизнеса
        categories = await category_service.get_by_business_slug(business_slug)
        print(f"\n📋 Всего категорий: {len(categories)}")
        
        # Подсчитываем количество товаров для каждой категории
        empty_categories = []
        categories_with_products = []
        
        for category in categories:
            # Подсчитываем количество товаров в категории
            stmt = select(func.count()).select_from(
                product_categories
            ).where(
                product_categories.c.category_id == category.id
            )
            result = await db.execute(stmt)
            product_count = result.scalar() or 0
            
            if product_count == 0:
                empty_categories.append(category)
                print(f"  ⚠️  Пустая категория: '{category.name}' (ID: {category.id})")
            else:
                categories_with_products.append((category, product_count))
                print(f"  ✅ Категория '{category.name}': {product_count} товаров")
        
        if not empty_categories:
            print(f"\n✅ Пустых категорий не найдено!")
            await engine.dispose()
            return
        
        print(f"\n🗑️  Удаление {len(empty_categories)} пустых категорий...")
        
        deleted_count = 0
        for category in empty_categories:
            try:
                success = await category_service.delete(category.id)
                if success:
                    print(f"  ✅ Удалена категория: '{category.name}'")
                    deleted_count += 1
                else:
                    print(f"  ⚠️  Не удалось удалить категорию: '{category.name}'")
            except Exception as e:
                print(f"  ❌ Ошибка при удалении '{category.name}': {e}")
        
        print(f"\n📊 Итоги:")
        print(f"  - Удалено пустых категорий: {deleted_count}")
        print(f"  - Осталось категорий с товарами: {len(categories_with_products)}")
        if categories_with_products:
            print(f"\n  Активные категории:")
            for category, count in categories_with_products:
                print(f"    - '{category.name}': {count} товаров")
        
        print(f"\n✅ Удаление завершено!")
    
    await engine.dispose()


if __name__ == "__main__":
    print("🚀 Удаление пустых категорий...\n")
    asyncio.run(delete_empty_categories())




