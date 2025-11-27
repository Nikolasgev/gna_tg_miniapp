"""Скрипт для обновления изображений товаров."""
import asyncio
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker
from sqlalchemy import select

from app.config import settings
from app.models.business import Business
from app.models.product import Product
from app.services.product_service import ProductService


# Ссылки на PNG изображения с прозрачным фоном
# ВАЖНО: Замените эти ссылки на реальные рабочие ссылки на PNG изображения
# Рекомендуется загрузить изображения на свой сервер или использовать надежные CDN
# 
# Для тестирования используются placeholder изображения, которые точно работают
# В продакшене замените на реальные изображения
PRODUCT_IMAGES = {
    # Кофе - замените на реальные PNG изображения
    "COFFEE-001": "https://via.placeholder.com/400x400/6F4E37/FFFFFF?text=Espresso",  # Эспрессо
    "COFFEE-002": "https://via.placeholder.com/400x400/8B4513/FFFFFF?text=Cappuccino",  # Капучино
    "COFFEE-003": "https://via.placeholder.com/400x400/D2B48C/FFFFFF?text=Latte",  # Латте
    "COFFEE-004": "https://via.placeholder.com/400x400/6F4E37/FFFFFF?text=Americano",  # Американо
    
    # Десерты - замените на реальные PNG изображения
    "DESSERT-001": "https://via.placeholder.com/400x400/FFB6C1/FFFFFF?text=Cheesecake",  # Чизкейк
    "DESSERT-002": "https://via.placeholder.com/400x400/DEB887/FFFFFF?text=Tiramisu",  # Тирамису
    "DESSERT-003": "https://via.placeholder.com/400x400/8B4513/FFFFFF?text=Brownie",  # Брауни
    "DESSERT-004": "https://via.placeholder.com/400x400/FFE4E1/FFFFFF?text=Ice+Cream",  # Мороженое
    
    # Напитки - замените на реальные PNG изображения
    "DRINK-001": "https://via.placeholder.com/400x400/FFA500/FFFFFF?text=Orange+Juice",  # Апельсиновый сок
    "DRINK-002": "https://via.placeholder.com/400x400/FFFF00/000000?text=Lemonade",  # Лимонад
    "DRINK-003": "https://via.placeholder.com/400x400/FF6347/FFFFFF?text=Juice",  # Морс
    "DRINK-004": "https://via.placeholder.com/400x400/8B4513/FFFFFF?text=Hot+Chocolate",  # Горячий шоколад
}

# ИНСТРУКЦИЯ ПО ЗАМЕНЕ ИЗОБРАЖЕНИЙ:
# 1. Найдите PNG изображения с прозрачным фоном на сайтах:
#    - https://www.flaticon.com (иконки)
#    - https://www.freepik.com (иллюстрации)
#    - https://www.pngtree.com (PNG изображения)
#    - https://www.pexels.com (фотографии, можно убрать фон)
# 
# 2. Загрузите изображения на свой сервер или используйте прямые ссылки на CDN
# 
# 3. Замените ссылки в словаре PRODUCT_IMAGES выше
# 
# 4. Запустите скрипт снова: python update_product_images.py


async def update_product_images():
    """Обновить изображения для товаров."""
    
    engine = create_async_engine(settings.database_url, echo=False)
    async_session = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)
    
    async with async_session() as db:
        product_service = ProductService(db)
        
        # Находим бизнес
        business_slug = "default-business"
        stmt = select(Business).where(Business.slug == business_slug)
        result = await db.execute(stmt)
        business = result.scalar_one_or_none()
        
        if not business:
            print(f"❌ Бизнес с slug '{business_slug}' не найден")
            return
        
        print(f"✅ Найден бизнес: {business.name} (slug: {business.slug})\n")
        
        # Получаем все товары бизнеса
        products = await product_service.get_by_business_slug(
            business_slug,
            include_inactive=True,
        )
        
        updated_count = 0
        not_found_count = 0
        
        for product in products:
            if product.sku and product.sku in PRODUCT_IMAGES:
                image_url = PRODUCT_IMAGES[product.sku]
                
                # Обновляем товар
                await product_service.update(
                    product_id=product.id,
                    image_url=image_url,
                )
                
                updated_count += 1
                print(f"✅ Обновлен товар: {product.title} (SKU: {product.sku})")
                print(f"   Изображение: {image_url}")
            else:
                if product.sku:
                    not_found_count += 1
                    print(f"⚠️  Изображение не найдено для товара: {product.title} (SKU: {product.sku})")
        
        print(f"\n📊 Итого:")
        print(f"  - Обновлено товаров: {updated_count}")
        print(f"  - Не найдено изображений: {not_found_count}")
        print(f"\n✅ Обновление изображений завершено!")
        print(f"\n💡 Примечание: Изображения загружаются через image proxy для обхода CORS.")
        print(f"   Frontend автоматически использует /api/v1/images/proxy?url=... для загрузки изображений.")
        print(f"\n⚠️  ВНИМАНИЕ: Используются placeholder изображения для тестирования.")
        print(f"   Замените их на реальные PNG изображения в файле update_product_images.py")
        print(f"   См. инструкцию в начале файла.")
    
    await engine.dispose()


if __name__ == "__main__":
    print("🖼️  Обновление изображений товаров...\n")
    asyncio.run(update_product_images())
