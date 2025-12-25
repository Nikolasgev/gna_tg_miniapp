"""Скрипт для создания бизнеса косметики для волос."""
import asyncio
from decimal import Decimal
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine
from sqlalchemy.orm import sessionmaker

from app.config import settings
from app.services.business_service import BusinessService
from app.services.category_service import CategoryService
from app.services.product_service import ProductService
from app.services.setting_service import SettingService
from app.models.user import User
from sqlalchemy import select


async def create_hair_cosmetics_business():
    """Создать бизнес косметики для волос с категориями и товарами."""
    
    # Создаем подключение к БД
    engine = create_async_engine(settings.database_url, echo=False)
    async_session = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)
    
    async with async_session() as db:
        business_service = BusinessService(db)
        category_service = CategoryService(db)
        product_service = ProductService(db)
        setting_service = SettingService(db)
        
        # Получаем или создаем бизнес
        business_slug = "hair-cosmetics"
        business = await business_service.get_by_slug(business_slug)
        
        if not business:
            # Пытаемся найти любого пользователя для owner_id
            stmt_user = select(User).limit(1)
            result_user = await db.execute(stmt_user)
            user = result_user.scalar_one_or_none()
            
            if not user:
                # Создаем дефолтного пользователя
                import uuid
                user = User(
                    id=uuid.uuid4(),
                    telegram_id=123456789,  # Тестовый ID
                    username="demo_user",
                    first_name="Demo",
                    last_name="User",
                )
                db.add(user)
                await db.commit()
                await db.refresh(user)
                print(f"✅ Создан дефолтный пользователь: {user.username}")
            
            # Создаем бизнес
            business = await business_service.create(
                owner_id=user.id,
                name="Косметика для волос",
                slug=business_slug,
                description="Магазин профессиональной косметики для ухода за волосами",
            )
            print(f"✅ Создан бизнес: {business.name} (slug: {business.slug})")
        else:
            print(f"✅ Найден бизнес: {business.name} (slug: {business.slug})")
        
        # Настраиваем тему бизнеса (цвета для косметики)
        # Используем розовые/фиолетовые оттенки, подходящие для косметики
        theme_settings = {
            "primary_color": "#C2185B",  # Розовый для косметики
            "background_color": "#FFF5F8",  # Светло-розовый фон
            "text_color": "#2C1810",  # Темный текст
        }
        
        for key, value in theme_settings.items():
            await setting_service.set(business.id, key, {"value": value})
        
        print(f"✅ Настроены цвета темы бизнеса")
        
        # Создаем категории только для ухода за волосами
        categories_data = [
            {
                "name": "Шампуни",
                "position": 1,
                "surcharge": Decimal("0.00"),
            },
            {
                "name": "Кондиционеры",
                "position": 2,
                "surcharge": Decimal("0.00"),
            },
            {
                "name": "Маски для волос",
                "position": 3,
                "surcharge": Decimal("0.00"),
            },
            {
                "name": "Масла и сыворотки",
                "position": 4,
                "surcharge": Decimal("0.00"),
            },
            {
                "name": "Средства для укладки",
                "position": 5,
                "surcharge": Decimal("0.00"),
            },
            {
                "name": "Окрашивание",
                "position": 6,
                "surcharge": Decimal("0.00"),
            },
        ]
        
        created_categories = {}
        for cat_data in categories_data:
            # Проверяем, существует ли категория
            existing_categories = await category_service.get_by_business_slug(business_slug)
            existing = next((c for c in existing_categories if c.name == cat_data["name"]), None)
            
            if existing:
                print(f"⚠️  Категория '{cat_data['name']}' уже существует, пропускаем")
                created_categories[cat_data["name"]] = existing
            else:
                category = await category_service.create(
                    business_id=business.id,
                    name=cat_data["name"],
                    position=cat_data["position"],
                    surcharge=cat_data["surcharge"],
                )
                created_categories[cat_data["name"]] = category
                print(f"✅ Создана категория: {category.name} (ID: {category.id})")
        
        # Создаем товары для косметики для волос
        products_data = [
            # Шампуни
            {
                "title": "Шампунь для объема",
                "description": "Придает волосам объем и пышность. Подходит для тонких волос",
                "price": Decimal("890.00"),
                "sku": "HAIR-SHAMP-001",
                "category": "Шампуни",
            },
            {
                "title": "Шампунь для поврежденных волос",
                "description": "Интенсивное восстановление. С кератином и протеинами",
                "price": Decimal("990.00"),
                "sku": "HAIR-SHAMP-002",
                "category": "Шампуни",
            },
            {
                "title": "Шампунь для жирных волос",
                "description": "Матирующий эффект, контролирует выделение себума",
                "price": Decimal("850.00"),
                "sku": "HAIR-SHAMP-003",
                "category": "Шампуни",
            },
            {
                "title": "Шампунь для сухих волос",
                "description": "Интенсивное увлажнение. С маслами арганы и кокоса",
                "price": Decimal("950.00"),
                "sku": "HAIR-SHAMP-004",
                "category": "Шампуни",
            },
            {
                "title": "Безсульфатный шампунь",
                "description": "Мягкое очищение для чувствительной кожи головы",
                "price": Decimal("1100.00"),
                "sku": "HAIR-SHAMP-005",
                "category": "Шампуни",
            },
            # Кондиционеры
            {
                "title": "Кондиционер для волос",
                "description": "Восстанавливающий кондиционер с кератином. Разглаживает и питает волосы",
                "price": Decimal("950.00"),
                "sku": "HAIR-COND-001",
                "category": "Кондиционеры",
            },
            {
                "title": "Кондиционер для объема",
                "description": "Легкий кондиционер, не утяжеляет волосы",
                "price": Decimal("890.00"),
                "sku": "HAIR-COND-002",
                "category": "Кондиционеры",
            },
            {
                "title": "Кондиционер-спрей",
                "description": "Быстрый уход без смывания. Для ежедневного использования",
                "price": Decimal("650.00"),
                "sku": "HAIR-COND-003",
                "category": "Кондиционеры",
            },
            # Маски для волос
            {
                "title": "Маска для волос",
                "description": "Интенсивное восстановление поврежденных волос. С аргановым маслом",
                "price": Decimal("1290.00"),
                "sku": "HAIR-MASK-001",
                "category": "Маски для волос",
            },
            {
                "title": "Маска для объема",
                "description": "Придает волосам объем и упругость. С протеинами",
                "price": Decimal("1190.00"),
                "sku": "HAIR-MASK-002",
                "category": "Маски для волос",
            },
            {
                "title": "Маска для блеска",
                "description": "Добавляет волосам здоровый блеск и сияние",
                "price": Decimal("1090.00"),
                "sku": "HAIR-MASK-003",
                "category": "Маски для волос",
            },
            {
                "title": "Маска для окрашенных волос",
                "description": "Сохраняет цвет, питает и защищает окрашенные волосы",
                "price": Decimal("1390.00"),
                "sku": "HAIR-MASK-004",
                "category": "Маски для волос",
            },
            # Масла и сыворотки
            {
                "title": "Масло для кончиков волос",
                "description": "Защита и питание кончиков волос. Предотвращает сечение",
                "price": Decimal("690.00"),
                "sku": "HAIR-OIL-001",
                "category": "Масла и сыворотки",
            },
            {
                "title": "Аргановое масло",
                "description": "Универсальное масло для всех типов волос. Придает блеск и мягкость",
                "price": Decimal("890.00"),
                "sku": "HAIR-OIL-002",
                "category": "Масла и сыворотки",
            },
            {
                "title": "Сыворотка для роста волос",
                "description": "Стимулирует рост волос. С пептидами и биотином",
                "price": Decimal("1590.00"),
                "sku": "HAIR-SERUM-001",
                "category": "Масла и сыворотки",
            },
            {
                "title": "Сыворотка от выпадения",
                "description": "Укрепляет корни волос, предотвращает выпадение",
                "price": Decimal("1790.00"),
                "sku": "HAIR-SERUM-002",
                "category": "Масла и сыворотки",
            },
            # Средства для укладки
            {
                "title": "Термозащитный спрей",
                "description": "Защита волос от высоких температур при укладке",
                "price": Decimal("750.00"),
                "sku": "HAIR-STYLE-001",
                "category": "Средства для укладки",
            },
            {
                "title": "Лак для волос",
                "description": "Надежная фиксация прически. Сильная фиксация",
                "price": Decimal("590.00"),
                "sku": "HAIR-STYLE-002",
                "category": "Средства для укладки",
            },
            {
                "title": "Мусс для объема",
                "description": "Создает объем и упругость. Для корней волос",
                "price": Decimal("690.00"),
                "sku": "HAIR-STYLE-003",
                "category": "Средства для укладки",
            },
            {
                "title": "Пена для укладки",
                "description": "Гибкая фиксация, естественный вид",
                "price": Decimal("650.00"),
                "sku": "HAIR-STYLE-004",
                "category": "Средства для укладки",
            },
            # Окрашивание
            {
                "title": "Краска для волос (1 шт)",
                "description": "Профессиональная краска для волос. Богатая палитра оттенков",
                "price": Decimal("450.00"),
                "sku": "HAIR-DYE-001",
                "category": "Окрашивание",
            },
            {
                "title": "Окислитель для краски",
                "description": "Профессиональный окислитель 3%, 6%, 9%",
                "price": Decimal("350.00"),
                "sku": "HAIR-DYE-002",
                "category": "Окрашивание",
            },
            {
                "title": "Блондирующий порошок",
                "description": "Для осветления волос. С аммиаком",
                "price": Decimal("550.00"),
                "sku": "HAIR-DYE-003",
                "category": "Окрашивание",
            },
            {
                "title": "Тонирующая маска",
                "description": "Коррекция оттенка, придание блеска. Без аммиака",
                "price": Decimal("790.00"),
                "sku": "HAIR-DYE-004",
                "category": "Окрашивание",
            },
        ]
        
        # Проверяем существующие товары
        existing_products = await product_service.get_by_business_slug(
            business_slug,
            include_inactive=True,
        )
        existing_skus = {p.sku for p in existing_products if p.sku}
        
        created_count = 0
        skipped_count = 0
        
        for product_data in products_data:
            # Пропускаем, если товар уже существует
            if product_data["sku"] in existing_skus:
                print(f"⚠️  Товар с SKU '{product_data['sku']}' уже существует, пропускаем")
                skipped_count += 1
                continue
            
            category = created_categories[product_data["category"]]
            category_ids = [category.id]
            
            # Создаем товар
            product_id = await product_service.create(
                business_id=business.id,
                title=product_data["title"],
                description=product_data.get("description"),
                price=product_data["price"],
                currency="RUB",
                sku=product_data["sku"],
                image_url=product_data.get("image_url"),
                variations=product_data.get("variations"),
                category_ids=category_ids,
            )
            
            # Получаем созданный товар для вывода информации
            product = await product_service.get_by_id(product_id)
            
            created_count += 1
            if product:
                print(f"✅ Создан товар: {product.title} - {product.price} ₽ (SKU: {product.sku})")
            else:
                print(f"✅ Создан товар: {product_data['title']} - {product_data['price']} ₽ (SKU: {product_data['sku']})")
        
        print(f"\n📊 Итого:")
        print(f"  - Бизнес: {business.name} (slug: {business_slug})")
        print(f"  - Категорий: {len(created_categories)}")
        print(f"  - Товаров создано: {created_count}")
        print(f"  - Товаров пропущено: {skipped_count}")
        print(f"\n✅ Бизнес косметики для волос успешно создан!")
    
    await engine.dispose()


if __name__ == "__main__":
    print("🚀 Создание бизнеса косметики для волос...\n")
    asyncio.run(create_hair_cosmetics_business())




