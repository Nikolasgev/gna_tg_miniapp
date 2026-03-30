"""Скрипт для создания демо-меню."""
import asyncio
from decimal import Decimal
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine
from sqlalchemy.orm import sessionmaker

from app.config import settings
from app.database import Base, get_db
from app.services.business_service import BusinessService
from app.services.category_service import CategoryService
from app.services.product_service import ProductService
from app.models.user import User
from app.models.business import Business
from sqlalchemy import select


async def create_demo_menu():
    """Создать демо-меню с категориями и товарами."""
    
    # Создаем подключение к БД
    engine = create_async_engine(settings.database_url, echo=False)
    async_session = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)
    
    async with async_session() as db:
        business_service = BusinessService(db)
        category_service = CategoryService(db)
        product_service = ProductService(db)
        
        # Получаем или создаем бизнес
        # Используем slug, который используется в админ-панели
        business_slug = "default-business"
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
                name="Демо-кафе",
                slug=business_slug,
                description="Демонстрационное кафе для тестирования",
            )
            print(f"✅ Создан бизнес: {business.name} (slug: {business.slug})")
        
        print(f"✅ Найден бизнес: {business.name} (slug: {business.slug})")
        
        # Создаем категории
        categories_data = [
            {
                "name": "Кофе",
                "position": 1,
                "surcharge": Decimal("0.00"),
            },
            {
                "name": "Десерты",
                "position": 2,
                "surcharge": Decimal("0.00"),
            },
            {
                "name": "Напитки",
                "position": 3,
                "surcharge": Decimal("0.00"),
            },
            # Категории косметики
            {
                "name": "Уход за лицом",
                "position": 11,
                "surcharge": Decimal("0.00"),
            },
            {
                "name": "Уход за телом",
                "position": 12,
                "surcharge": Decimal("0.00"),
            },
            {
                "name": "Уход за волосами",
                "position": 13,
                "surcharge": Decimal("0.00"),
            },
            {
                "name": "Сыворотки и концентраты",
                "position": 14,
                "surcharge": Decimal("0.00"),
            },
            {
                "name": "Маски для лица",
                "position": 15,
                "surcharge": Decimal("0.00"),
            },
            {
                "name": "Средства для очищения",
                "position": 16,
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
        
        # Создаем товары
        products_data = [
            # Кофе
            {
                "title": "Эспрессо",
                "description": "Классический крепкий кофе",
                "price": Decimal("150.00"),
                "sku": "COFFEE-001",
                "category": "Кофе",
                "variations": {
                    "размер": {
                        "маленький": 0,
                        "средний": 30,
                        "большой": 50,
                    }
                },
            },
            {
                "title": "Капучино",
                "description": "Эспрессо с молочной пеной",
                "price": Decimal("200.00"),
                "sku": "COFFEE-002",
                "category": "Кофе",
                "variations": {
                    "размер": {
                        "маленький": 0,
                        "средний": 30,
                        "большой": 50,
                    }
                },
            },
            {
                "title": "Латте",
                "description": "Эспрессо с большим количеством молока",
                "price": Decimal("220.00"),
                "sku": "COFFEE-003",
                "category": "Кофе",
                "variations": {
                    "размер": {
                        "маленький": 0,
                        "средний": 30,
                        "большой": 50,
                    }
                },
            },
            {
                "title": "Американо",
                "description": "Эспрессо с горячей водой",
                "price": Decimal("180.00"),
                "sku": "COFFEE-004",
                "category": "Кофе",
                "variations": {
                    "размер": {
                        "маленький": 0,
                        "средний": 30,
                        "большой": 50,
                    }
                },
            },
            # Десерты
            {
                "title": "Чизкейк",
                "description": "Нежный чизкейк с ягодным соусом",
                "price": Decimal("350.00"),
                "sku": "DESSERT-001",
                "category": "Десерты",
            },
            {
                "title": "Тирамису",
                "description": "Классический итальянский десерт",
                "price": Decimal("380.00"),
                "sku": "DESSERT-002",
                "category": "Десерты",
            },
            {
                "title": "Брауни",
                "description": "Шоколадный брауни с орехами",
                "price": Decimal("280.00"),
                "sku": "DESSERT-003",
                "category": "Десерты",
            },
            {
                "title": "Мороженое",
                "description": "Домашнее мороженое (3 шарика)",
                "price": Decimal("250.00"),
                "sku": "DESSERT-004",
                "category": "Десерты",
            },
            # Напитки
            {
                "title": "Свежевыжатый апельсиновый сок",
                "description": "200 мл свежевыжатого сока",
                "price": Decimal("180.00"),
                "sku": "DRINK-001",
                "category": "Напитки",
            },
            {
                "title": "Лимонад",
                "description": "Домашний лимонад с мятой",
                "price": Decimal("150.00"),
                "sku": "DRINK-002",
                "category": "Напитки",
            },
            {
                "title": "Морс",
                "description": "Клюквенный морс",
                "price": Decimal("120.00"),
                "sku": "DRINK-003",
                "category": "Напитки",
            },
            {
                "title": "Горячий шоколад",
                "description": "Густой горячий шоколад со взбитыми сливками",
                "price": Decimal("200.00"),
                "sku": "DRINK-004",
                "category": "Напитки",
            },
            # Уход за лицом
            {
                "title": "Увлажняющий крем для лица",
                "description": "Интенсивное увлажнение для всех типов кожи. Содержит гиалуроновую кислоту и витамин Е",
                "price": Decimal("1290.00"),
                "sku": "COSM-FACE-001",
                "category": "Уход за лицом",
            },
            {
                "title": "Очищающий гель для умывания",
                "description": "Мягкое очищение для чувствительной кожи. Без сульфатов и парабенов",
                "price": Decimal("890.00"),
                "sku": "COSM-FACE-002",
                "category": "Уход за лицом",
            },
            {
                "title": "Антивозрастной крем",
                "description": "Активный уход против первых признаков старения. С пептидами и ретинолом",
                "price": Decimal("2490.00"),
                "sku": "COSM-FACE-003",
                "category": "Уход за лицом",
            },
            {
                "title": "Тоник для лица",
                "description": "Освежающий тоник с экстрактом розы. Восстанавливает pH-баланс кожи",
                "price": Decimal("650.00"),
                "sku": "COSM-FACE-004",
                "category": "Уход за лицом",
            },
            # Уход за телом
            {
                "title": "Увлажняющее молочко для тела",
                "description": "Легкая текстура, быстро впитывается. Обогащено маслом ши и витамином Е",
                "price": Decimal("990.00"),
                "sku": "COSM-BODY-001",
                "category": "Уход за телом",
            },
            {
                "title": "Скраб для тела",
                "description": "Отшелушивающий скраб с частицами кофе и кокосовым маслом",
                "price": Decimal("750.00"),
                "sku": "COSM-BODY-002",
                "category": "Уход за телом",
            },
            {
                "title": "Масло для тела",
                "description": "Питательное масло с аргановым и жожоба маслами для интенсивного ухода",
                "price": Decimal("1190.00"),
                "sku": "COSM-BODY-003",
                "category": "Уход за телом",
            },
            # Уход за волосами
            {
                "title": "Шампунь для объема",
                "description": "Придает волосам объем и пышность. Подходит для тонких волос",
                "price": Decimal("890.00"),
                "sku": "COSM-HAIR-001",
                "category": "Уход за волосами",
            },
            {
                "title": "Кондиционер для волос",
                "description": "Восстанавливающий кондиционер с кератином. Разглаживает и питает волосы",
                "price": Decimal("950.00"),
                "sku": "COSM-HAIR-002",
                "category": "Уход за волосами",
            },
            {
                "title": "Маска для волос",
                "description": "Интенсивное восстановление поврежденных волос. С аргановым маслом",
                "price": Decimal("1290.00"),
                "sku": "COSM-HAIR-003",
                "category": "Уход за волосами",
            },
            {
                "title": "Масло для кончиков волос",
                "description": "Защита и питание кончиков волос. Предотвращает сечение",
                "price": Decimal("690.00"),
                "sku": "COSM-HAIR-004",
                "category": "Уход за волосами",
            },
            # Сыворотки и концентраты
            {
                "title": "Сыворотка с витамином C",
                "description": "Осветляет кожу, выравнивает тон. Антиоксидантная защита",
                "price": Decimal("1890.00"),
                "sku": "COSM-SERUM-001",
                "category": "Сыворотки и концентраты",
            },
            {
                "title": "Ниацинамид сыворотка",
                "description": "Сужение пор, матирование, выравнивание текстуры кожи",
                "price": Decimal("1590.00"),
                "sku": "COSM-SERUM-002",
                "category": "Сыворотки и концентраты",
            },
            {
                "title": "Гиалуроновая кислота",
                "description": "Интенсивное увлажнение. Концентрат гиалуроновой кислоты",
                "price": Decimal("1390.00"),
                "sku": "COSM-SERUM-003",
                "category": "Сыворотки и концентраты",
            },
            {
                "title": "Ретинол концентрат",
                "description": "Антивозрастной уход. Разглаживает морщины, обновляет кожу",
                "price": Decimal("2290.00"),
                "sku": "COSM-SERUM-004",
                "category": "Сыворотки и концентраты",
            },
            # Маски для лица
            {
                "title": "Глиняная маска",
                "description": "Очищающая маска с зеленой глиной. Детокс и сужение пор",
                "price": Decimal("790.00"),
                "sku": "COSM-MASK-001",
                "category": "Маски для лица",
            },
            {
                "title": "Увлажняющая тканевая маска",
                "description": "Интенсивное увлажнение за 15 минут. С гиалуроновой кислотой",
                "price": Decimal("199.00"),
                "sku": "COSM-MASK-002",
                "category": "Маски для лица",
            },
            {
                "title": "Альгинатная маска",
                "description": "Лифтинг-эффект и увлажнение. Подтягивает контуры лица",
                "price": Decimal("1490.00"),
                "sku": "COSM-MASK-003",
                "category": "Маски для лица",
            },
            # Средства для очищения
            {
                "title": "Мицеллярная вода",
                "description": "Бережное снятие макияжа и очищение. Для всех типов кожи",
                "price": Decimal("690.00"),
                "sku": "COSM-CLEAN-001",
                "category": "Средства для очищения",
            },
            {
                "title": "Очищающее масло",
                "description": "Двухфазное очищение. Растворяет макияж и загрязнения",
                "price": Decimal("890.00"),
                "sku": "COSM-CLEAN-002",
                "category": "Средства для очищения",
            },
            {
                "title": "Энзимный порошок для умывания",
                "description": "Мягкое отшелушивание. С папаином для обновления кожи",
                "price": Decimal("1190.00"),
                "sku": "COSM-CLEAN-003",
                "category": "Средства для очищения",
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
            category_ids = [str(category.id)]
            
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
        print(f"  - Категорий: {len(created_categories)}")
        print(f"  - Товаров создано: {created_count}")
        print(f"  - Товаров пропущено: {skipped_count}")
        print(f"\n✅ Демо-меню успешно создано!")
    
    await engine.dispose()


if __name__ == "__main__":
    print("🚀 Создание демо-меню...\n")
    asyncio.run(create_demo_menu())

