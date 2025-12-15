"""Скрипт для добавления масок KLOR и KBYO в бизнес косметики для волос."""
import asyncio
import shutil
from decimal import Decimal
from pathlib import Path
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine
from sqlalchemy.orm import sessionmaker
import uuid

from app.config import settings
from app.services.business_service import BusinessService
from app.services.category_service import CategoryService
from app.services.product_service import ProductService

# Путь к папке с исходными изображениями (относительно корня проекта)
# __file__ = backend/add_mask_products.py
# parent = backend/
# parent.parent = корень проекта
SOURCE_IMAGES_DIR = Path(__file__).parent.parent / "images"
# Путь к папке для загруженных изображений
UPLOAD_DIR = Path(__file__).parent / "uploads" / "images"
UPLOAD_DIR.mkdir(parents=True, exist_ok=True)


async def add_mask_products():
    """Добавить маски KLOR и KBYO в бизнес косметики для волос."""
    
    # Создаем подключение к БД
    engine = create_async_engine(settings.database_url, echo=False)
    async_session = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)
    
    async with async_session() as db:
        business_service = BusinessService(db)
        category_service = CategoryService(db)
        product_service = ProductService(db)
        
        # Получаем бизнес косметики для волос
        business_slug = "hair-cosmetics"
        business = await business_service.get_by_slug(business_slug)
        
        if not business:
            print(f"❌ Бизнес с slug '{business_slug}' не найден")
            print(f"   Сначала запустите: python create_hair_cosmetics_business.py")
            return
        
        print(f"✅ Найден бизнес: {business.name} (slug: {business.slug})\n")
        
        # Получаем категории
        categories = await category_service.get_by_business_slug(business_slug)
        category_map = {cat.name: cat for cat in categories}
        
        # Проверяем наличие нужных категорий
        masks_category = category_map.get("Маски для волос")
        coloring_category = category_map.get("Окрашивание")
        
        if not masks_category:
            print("❌ Категория 'Маски для волос' не найдена")
            return
        
        if not coloring_category:
            print("❌ Категория 'Окрашивание' не найдена")
            return
        
        print(f"✅ Найдены категории:")
        print(f"   - Маски для волос (ID: {masks_category.id})")
        print(f"   - Окрашивание (ID: {coloring_category.id})\n")
        
        # Копируем изображения
        print("📁 Копирование изображений...")
        image_mapping = {}  # {source_file: uploaded_url}
        
        # Изображения для KLOR MASK (первые 3)
        klor_images = ["image.png", "image (1).png", "image (2).png"]
        # Изображения для KBYO/MSKA MASK (вторые 3)
        kbyo_images = ["image (3).png", "image (4).png", "image (5).png"]
        
        all_images = klor_images + kbyo_images
        
        for img_name in all_images:
            source_path = SOURCE_IMAGES_DIR / img_name
            # Используем абсолютный путь
            if not source_path.exists():
                # Пробуем с абсолютным путем
                source_path = Path("/app/images") / img_name
                if not source_path.exists():
                    print(f"⚠️  Изображение не найдено: {img_name}")
                    continue
            
            # Генерируем уникальное имя файла
            file_extension = source_path.suffix
            unique_filename = f"{uuid.uuid4()}{file_extension}"
            dest_path = UPLOAD_DIR / unique_filename
            
            # Копируем файл
            try:
                shutil.copy2(source_path, dest_path)
                image_url = f"/api/v1/images/uploads/{unique_filename}"
                image_mapping[img_name] = image_url
                print(f"✅ Скопировано: {img_name} -> {unique_filename}")
            except Exception as e:
                print(f"❌ Ошибка при копировании {img_name}: {e}")
        
        # Используем первое изображение как основное для каждого товара
        klor_main_image = image_mapping.get("image.png", None)
        kbyo_main_image = image_mapping.get("image (3).png", None)
        
        print()
        
        # Проверяем существующие товары
        existing_products = await product_service.get_by_business_slug(
            business_slug,
            include_inactive=True,
        )
        existing_skus = {p.sku for p in existing_products if p.sku}
        
        # Данные товаров
        products_data = [
            # KLOR MASK - маска для окрашенных волос (в категорию "Окрашивание")
            {
                "title": "KLOR MASK",
                "description": """Маска надежно защищает цвет от вымывания, оживляет и придает волосам блеск. Масло макадамии в составе маски способствует питанию и восстановлению волос разной степени повреждения, придает волосам мягкость и шелковистость. А благодаря маслу марулы и экстракту огурца сохраняется влага внутри структуры волоса. Так же сохраняет цвет от выгорания на солнце благодаря UF-фильтрам в составе маски.""",
                "price": Decimal("0.00"),  # Цена будет указана в вариантах
                "sku": "KOKMSKLOR",
                "category": "Окрашивание",
                "variations": {
                    "Объем": {
                        "250 мл": 0.0,  # Здесь нужно указать реальную цену
                        "500 мл": 0.0,  # Здесь нужно указать реальную цену
                    }
                },
                # Изображения: image.png, image (1).png, image (2).png
                # Нужно будет загрузить через API /api/v1/images/upload
            },
            # KBYO/MSKA MASK - маска с биотином (в категорию "Маски для волос")
            {
                "title": "KBYO/MSKA MASK",
                "description": """ВНИМАНИЕ! У НОВОЙ ПАРТИИ МАСОК KBYO 500МЛ - ГЛЯНЦЕВЫЕ КРЫШКИ.
Маски с такими крышками не являются браком или подделкой. Сравнение масок из старой и новой партии представлены на фото.

Многофункциональная липидно-силиконовая маска, предназначена для ежедневного применения как в домашних условиях так и для использования в салоне в качестве уходового и технического продукта. Маска укрепляет, питает, увлажняет и придает шелковистость и блеск волосам, создает защитные пленки на поверхности волоса, защищает от агрессивных факторов от окружающей среды и облегчает расчесывание. Гидролизованный соевый протеин, экстракт огурца и масло марулы оказывают сильное увлажняющее действие. Биотин в составе придает волосам прочность.""",
                "price": Decimal("0.00"),  # Цена будет указана в вариантах
                "sku": "KOMSKBYO250",
                "category": "Маски для волос",
                "variations": {
                    "Объем": {
                        "250 мл": 0.0,  # Здесь нужно указать реальную цену
                        "500 мл": 0.0,  # Здесь нужно указать реальную цену
                        "2000 мл": 0.0,  # Здесь нужно указать реальную цену
                    }
                },
                # Изображения: image (3).png, image (4).png, image (5).png
                # Нужно будет загрузить через API /api/v1/images/upload
            },
        ]
        
        created_count = 0
        skipped_count = 0
        
        for product_data in products_data:
            # Пропускаем, если товар уже существует
            if product_data["sku"] in existing_skus:
                print(f"⚠️  Товар с SKU '{product_data['sku']}' уже существует, пропускаем")
                skipped_count += 1
                continue
            
            category = category_map[product_data["category"]]
            category_ids = [category.id]
            
            # Определяем image_url для товара
            image_url = None
            if product_data["sku"] == "KOKMSKLOR":
                image_url = klor_main_image
            elif product_data["sku"] == "KOMSKBYO250":
                image_url = kbyo_main_image
            
            # Создаем товар
            product_id = await product_service.create(
                business_id=business.id,
                title=product_data["title"],
                description=product_data.get("description"),
                price=product_data["price"],
                currency="RUB",
                sku=product_data["sku"],
                image_url=image_url,
                variations=product_data.get("variations"),
                category_ids=category_ids,
            )
            
            # Получаем созданный товар для вывода информации
            product = await product_service.get_by_id(product_id)
            
            created_count += 1
            if product:
                print(f"✅ Создан товар: {product.title} (SKU: {product.sku})")
                print(f"   Категория: {product_data['category']}")
                if product_data.get("variations"):
                    print(f"   Варианты: {list(product_data['variations'].get('Объем', {}).keys())}")
                if image_url:
                    print(f"   Изображение: {image_url}")
            else:
                print(f"✅ Создан товар: {product_data['title']} (SKU: {product_data['sku']})")
        
        print(f"\n📊 Итого:")
        print(f"  - Товаров создано: {created_count}")
        print(f"  - Товаров пропущено: {skipped_count}")
        print(f"\n⚠️  ВАЖНО:")
        print(f"  1. Укажите реальные цены в вариациях товаров через админ-панель или API")
        print(f"  2. Дополнительные изображения (для галереи) нужно загрузить отдельно")
        print(f"\n✅ Товары успешно добавлены!")
    
    await engine.dispose()


if __name__ == "__main__":
    print("🚀 Добавление масок KLOR и KBYO...\n")
    asyncio.run(add_mask_products())
