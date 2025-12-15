"""Скрипт для удаления всех товаров из бизнеса косметики для волос."""
import asyncio
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy import select, delete
from sqlalchemy.orm import selectinload

from app.config import settings
from app.services.business_service import BusinessService
from app.models.product import Product
from app.models.product_category import product_categories


async def delete_hair_cosmetics_products():
    """Удалить все товары из бизнеса косметики для волос."""
    
    # Создаем подключение к БД
    engine = create_async_engine(settings.database_url, echo=False)
    async_session = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)
    
    async with async_session() as db:
        business_service = BusinessService(db)
        
        # Получаем бизнес косметики для волос
        business_slug = "hair-cosmetics"
        business = await business_service.get_by_slug(business_slug)
        
        if not business:
            print(f"❌ Бизнес с slug '{business_slug}' не найден")
            return
        
        print(f"✅ Найден бизнес: {business.name} (slug: {business.slug})\n")
        
        # Получаем все товары бизнеса
        stmt = select(Product).where(Product.business_id == business.id)
        result = await db.execute(stmt)
        products = result.scalars().all()
        
        if not products:
            print("ℹ️  Товары не найдены")
            return
        
        print(f"📦 Найдено товаров: {len(products)}")
        
        # Удаляем связи с категориями
        product_ids = [p.id for p in products]
        if product_ids:
            stmt_delete_links = delete(product_categories).where(
                product_categories.c.product_id.in_(product_ids)
            )
            await db.execute(stmt_delete_links)
            print(f"✅ Удалены связи с категориями")
        
        # Удаляем товары
        deleted_count = 0
        for product in products:
            await db.delete(product)
            deleted_count += 1
            print(f"  ✓ Удален: {product.title} (SKU: {product.sku})")
        
        await db.commit()
        
        print(f"\n📊 Итого удалено товаров: {deleted_count}")
        print(f"✅ Все товары успешно удалены!")
    
    await engine.dispose()


if __name__ == "__main__":
    print("🗑️  Удаление всех товаров из бизнеса косметики для волос...\n")
    asyncio.run(delete_hair_cosmetics_products())
