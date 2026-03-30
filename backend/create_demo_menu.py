"""Сид каталога для default-business — те же категории и товары, что в create_hair_cosmetics_business.py."""
import asyncio
import uuid

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine
from sqlalchemy.orm import sessionmaker

from app.config import settings
from app.data.hair_cosmetics_catalog import (
    HAIR_COSMETICS_CATEGORIES_DATA,
    HAIR_COSMETICS_PRODUCTS_DATA,
    HAIR_COSMETICS_THEME_SETTINGS,
)
from app.models.user import User
from app.services.business_service import BusinessService
from app.services.category_service import CategoryService
from app.services.product_service import ProductService
from app.services.setting_service import SettingService


async def create_demo_menu():
    """Создать категории и товары для default-business из hair_cosmetics_catalog."""
    engine = create_async_engine(settings.database_url, echo=False)
    async_session = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)

    async with async_session() as db:
        business_service = BusinessService(db)
        category_service = CategoryService(db)
        product_service = ProductService(db)
        setting_service = SettingService(db)

        business_slug = "default-business"
        business = await business_service.get_by_slug(business_slug)

        if not business:
            stmt_user = select(User).limit(1)
            result_user = await db.execute(stmt_user)
            user = result_user.scalar_one_or_none()

            if not user:
                user = User(
                    id=uuid.uuid4(),
                    telegram_id=123456789,
                    username="demo_user",
                    first_name="Demo",
                    last_name="User",
                )
                db.add(user)
                await db.commit()
                await db.refresh(user)
                print(f"✅ Создан дефолтный пользователь: {user.username}")

            business = await business_service.create(
                owner_id=user.id,
                name="Мой магазин",
                slug=business_slug,
                description="Основной бизнес",
            )
            print(f"✅ Создан бизнес: {business.name} (slug: {business.slug})")

        print(f"✅ Найден бизнес: {business.name} (slug: {business.slug})")

        for key, value in HAIR_COSMETICS_THEME_SETTINGS.items():
            await setting_service.set(business.id, key, {"value": value})
        print("✅ Настроены цвета темы бизнеса (как у hair-cosmetics)")

        categories_data = HAIR_COSMETICS_CATEGORIES_DATA
        products_data = HAIR_COSMETICS_PRODUCTS_DATA

        created_categories = {}
        for cat_data in categories_data:
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

        existing_products = await product_service.get_by_business_slug(
            business_slug,
            include_inactive=True,
        )
        existing_skus = {p.sku for p in existing_products if p.sku}

        created_count = 0
        skipped_count = 0

        for product_data in products_data:
            if product_data["sku"] in existing_skus:
                print(f"⚠️  Товар с SKU '{product_data['sku']}' уже существует, пропускаем")
                skipped_count += 1
                continue

            category = created_categories[product_data["category"]]
            category_ids = [category.id]

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
        print(f"\n✅ Демо-меню (каталог из hair_cosmetics_catalog) для {business_slug} готово!")

    await engine.dispose()


if __name__ == "__main__":
    print("🚀 Создание демо-меню (default-business, данные из hair_cosmetics_catalog)...\n")
    asyncio.run(create_demo_menu())
