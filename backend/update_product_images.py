"""Скрипт для обновления изображений товаров косметики."""
import asyncio
import os
from pathlib import Path
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine
from sqlalchemy.orm import sessionmaker
import httpx
from typing import Optional

from app.config import settings
from app.services.business_service import BusinessService
from app.services.product_service import ProductService
from sqlalchemy import select, update as sql_update
from app.models.product import Product


async def upload_image(image_path: str, base_url: str) -> Optional[str]:
    """Загрузить изображение на сервер и получить URL."""
    if not os.path.exists(image_path):
        print(f"⚠️  Изображение не найдено: {image_path}")
        return None
    
    try:
        async with httpx.AsyncClient(timeout=30.0) as client:
            with open(image_path, 'rb') as f:
                files = {'file': (os.path.basename(image_path), f, 'image/png')}
                response = await client.post(
                    f"{base_url}/api/v1/images/upload",
                    files=files,
                )
                
            if response.status_code == 200:
                data = response.json()
                image_url = data.get('url') or data.get('file_url')
                if image_url:
                    return image_url if image_url.startswith('/') else f"/{image_url}"
                return None
            else:
                print(f"⚠️  Ошибка загрузки изображения {image_path}: {response.status_code}")
                return None
    except Exception as e:
        print(f"⚠️  Ошибка при загрузке {image_path}: {e}")
        return None


async def update_product_images():
    """Обновить изображения товаров."""
    
    business_slug = "hair-cosmetics"
    base_url = settings.base_url if hasattr(settings, 'base_url') else "http://localhost:8000"
    
    # Путь к изображениям в контейнере
    images_dir = Path("/tmp/images")
    if not images_dir.exists():
        # Попробуем найти локально
        images_dir = Path(__file__).parent.parent / "images"
    
    print(f"📁 Ищу изображения в: {images_dir.absolute()}")
    
    # Создаем подключение к БД
    engine = create_async_engine(settings.database_url, echo=False)
    async_session = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)
    
    async with async_session() as db:
        business_service = BusinessService(db)
        product_service = ProductService(db)
        
        # Получаем бизнес
        business = await business_service.get_by_slug(business_slug)
        if not business:
            print(f"❌ Бизнес '{business_slug}' не найден!")
            await engine.dispose()
            return
        
        # Получаем товары по SKU
        products_to_update = {
            "KOKMSKLOR": "image.png",  # KLOR MASK
            "KOMSKBYO250": "image (3).png",  # KBYO/MSKA MASK (используем 4-е изображение)
        }
        
        print(f"\n📸 Загрузка и обновление изображений...")
        
        for sku, image_file in products_to_update.items():
            # Получаем товар
            stmt = select(Product).where(
                Product.business_id == business.id,
                Product.sku == sku
            )
            result = await db.execute(stmt)
            product = result.scalar_one_or_none()
            
            if not product:
                print(f"⚠️  Товар с SKU '{sku}' не найден")
                continue
            
            # Загружаем изображение
            img_path = images_dir / image_file
            print(f"  Товар {sku}: {product.title}")
            print(f"  Загружаю {image_file}...")
            
            if img_path.exists():
                image_url = await upload_image(str(img_path), base_url)
                if image_url:
                    # Обновляем товар
                    stmt_update = sql_update(Product).where(
                        Product.id == product.id
                    ).values(image_url=image_url)
                    await db.execute(stmt_update)
                    await db.commit()
                    print(f"  ✅ Обновлено изображение: {image_url}")
                else:
                    print(f"  ⚠️  Не удалось загрузить изображение")
            else:
                print(f"  ⚠️  Файл не найден: {img_path}")
        
        print(f"\n✅ Обновление изображений завершено!")
    
    await engine.dispose()


if __name__ == "__main__":
    print("🚀 Обновление изображений товаров...\n")
    asyncio.run(update_product_images())
