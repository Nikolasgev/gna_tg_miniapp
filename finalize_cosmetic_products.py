"""Финальная настройка товаров косметики: обновление и активация."""
import asyncio
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy import select, update as sql_update
from decimal import Decimal

from app.config import settings
from app.services.business_service import BusinessService
from app.models.product import Product


async def finalize_cosmetic_products():
    """Финальная настройка товаров."""
    
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
        
        print(f"\n🔄 Обновление старых товаров...")
        
        # Обновляем старый товар KOMSKBYO250 - убираем варианты, обновляем название
        stmt = select(Product).where(
            Product.business_id == business.id,
            Product.sku == "KOMSKBYO250"
        )
        result = await db.execute(stmt)
        product = result.scalar_one_or_none()
        
        if product:
            stmt_update = sql_update(Product).where(
                Product.id == product.id
            ).values(
                title="KBYO/MSKA MASK 250 мл",
                variations=None,  # Убираем варианты
                is_active=True,
                price=Decimal("1100.00")
            )
            await db.execute(stmt_update)
            await db.commit()
            print(f"  ✅ Обновлен товар KOMSKBYO250: убраны варианты, обновлено название")
        
        # Активируем KOKMSKLOR (третий товар KLOR)
        stmt = select(Product).where(
            Product.business_id == business.id,
            Product.sku == "KOKMSKLOR"
        )
        result = await db.execute(stmt)
        product = result.scalar_one_or_none()
        
        if product:
            stmt_update = sql_update(Product).where(
                Product.id == product.id
            ).values(
                is_active=True,
                variations=None,  # Убираем варианты, если были
                price=Decimal("1200.00")
            )
            await db.execute(stmt_update)
            await db.commit()
            print(f"  ✅ Активирован товар KOKMSKLOR")
        
        print(f"\n📊 Итоговый список активных товаров:")
        
        # Получаем все активные товары
        stmt = select(Product).where(
            Product.business_id == business.id,
            Product.is_active == True
        ).order_by(Product.sku)
        result = await db.execute(stmt)
        products = result.scalars().all()
        
        print(f"\n   Категория 'Маски для окрашенных волос' (первые 3):")
        klor_products = [p for p in products if "KLOR" in p.sku or "KOKM" in p.sku]
        for p in sorted(klor_products, key=lambda x: x.sku):
            print(f"     - {p.sku}: {p.title} - {p.price} ₽")
        
        print(f"\n   Категория 'Маски для волос' (вторые 3):")
        kbyo_products = [p for p in products if "KBYO" in p.sku or "KOMSK" in p.sku]
        for p in sorted(kbyo_products, key=lambda x: x.sku):
            print(f"     - {p.sku}: {p.title} - {p.price} ₽")
        
        print(f"\n✅ Итого активных товаров: {len(products)}")
    
    await engine.dispose()


if __name__ == "__main__":
    print("🚀 Финальная настройка товаров...\n")
    asyncio.run(finalize_cosmetic_products())




