"""Деактивировать старые товары с вариантами."""
import asyncio
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy import select, update as sql_update

from app.config import settings
from app.services.business_service import BusinessService
from app.models.product import Product


async def deactivate_old_products():
    """Деактивировать старые товары."""
    
    business_slug = "hair-cosmetics"
    
    # Создаем подключение к БД
    engine = create_async_engine(settings.database_url, echo=False)
    async_session = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)
    
    async with async_session() as db:
        business_service = BusinessService(db)
        
        # Получаем бизнес
        business = await business_service.get_by_slug(business_slug)
        if not business:
            print(f"❌ Бизнес '{business_slug}' не найден!")
            await engine.dispose()
            return
        
        print(f"\n🔴 Деактивация старых товаров с вариантами...")
        
        # Деактивируем старые товары с вариантами
        old_skus = ["KOKMSKLOR", "KOMSKBYO250"]
        for sku in old_skus:
            stmt = select(Product).where(
                Product.business_id == business.id,
                Product.sku == sku
            )
            result = await db.execute(stmt)
            product = result.scalar_one_or_none()
            
            if product:
                # Деактивируем товар
                stmt_update = sql_update(Product).where(
                    Product.id == product.id
                ).values(is_active=False)
                await db.execute(stmt_update)
                await db.commit()
                print(f"  ✅ Деактивирован товар: {sku} - {product.title}")
            else:
                print(f"  ⚠️  Товар {sku} не найден")
        
        print(f"\n✅ Деактивация завершена!")
        print(f"\n📊 Теперь активны следующие товары:")
        print(f"   Категория 'Маски для окрашенных волос':")
        print(f"     - KOKMSKLOR250 (KLOR MASK 250 мл)")
        print(f"     - KOKMSKLOR500 (KLOR MASK 500 мл)")
        print(f"   Категория 'Маски для волос':")
        print(f"     - KOMSKBYO250 (KBYO/MSKA MASK 250 мл)")
        print(f"     - KOMSKBYO500 (KBYO/MSKA MASK 500 мл)")
        print(f"     - KOMSKBYO2000 (KBYO/MSKA MASK 2000 мл)")
    
    await engine.dispose()


if __name__ == "__main__":
    print("🚀 Деактивация старых товаров...\n")
    asyncio.run(deactivate_old_products())

