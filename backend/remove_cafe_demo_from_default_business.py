#!/usr/bin/env python3
"""
Удаляет из default-business старый демо-кафе и старый демо-каталог COSM-*
(до перехода на hair_cosmetics_catalog). Товары HAIR-* и категории шампуней и т.д. не трогает.

Использование:
    export DATABASE_URL="postgresql://..."
    python remove_cafe_demo_from_default_business.py
"""
import asyncio
import os
import sys

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine
from sqlalchemy.orm import sessionmaker, selectinload

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from app.models.business import Business
from app.models.category import Category
from app.models.product import Product

CAFE_CATEGORY_NAMES = frozenset({"Кофе", "Десерты", "Напитки"})
# Старый демо create_demo_menu (до hair_cosmetics_catalog)
LEGACY_COSM_CATEGORY_NAMES = frozenset(
    {
        "Уход за лицом",
        "Уход за телом",
        "Уход за волосами",
        "Сыворотки и концентраты",
        "Маски для лица",
        "Средства для очищения",
    }
)
# Старый демо create_demo_menu (COSM-*) — не из hair_cosmetics_catalog
CAFE_SKU_PREFIXES = ("COFFEE-", "DESSERT-", "DRINK-", "COSM-")


async def main() -> None:
    raw = os.getenv("DATABASE_URL")
    if not raw:
        print("❌ DATABASE_URL не задан")
        sys.exit(1)
    url = raw
    if url.startswith("postgresql://") and "+asyncpg" not in url:
        url = url.replace("postgresql://", "postgresql+asyncpg://", 1)
    elif not url.startswith("postgresql+asyncpg://"):
        print("❌ Ожидается postgresql:// или postgresql+asyncpg://")
        sys.exit(1)

    engine = create_async_engine(url, echo=False)
    async_session = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)

    async with async_session() as db:
        stmt = select(Business).where(Business.slug == "default-business")
        r = await db.execute(stmt)
        business = r.scalar_one_or_none()
        if not business:
            print("❌ Бизнес default-business не найден")
            await engine.dispose()
            sys.exit(1)

        stmt_p = (
            select(Product)
            .options(selectinload(Product.categories))
            .where(Product.business_id == business.id)
        )
        r2 = await db.execute(stmt_p)
        products = list(r2.scalars().unique().all())

        to_delete: list[Product] = []
        for p in products:
            if p.sku and p.sku.startswith(CAFE_SKU_PREFIXES):
                to_delete.append(p)
                continue
            names = {c.name for c in (p.categories or [])}
            if names & CAFE_CATEGORY_NAMES or names & LEGACY_COSM_CATEGORY_NAMES:
                to_delete.append(p)

        from app.services.product_service import ProductService

        ps = ProductService(db)
        for p in to_delete:
            await ps.delete(p.id)
            print(f"🗑 Удалён товар: {p.title} (SKU: {p.sku})")

        stmt_c = select(Category).where(Category.business_id == business.id)
        r3 = await db.execute(stmt_c)
        categories = list(r3.scalars().all())

        from app.services.category_service import CategoryService

        cs = CategoryService(db)
        legacy_cat = CAFE_CATEGORY_NAMES | LEGACY_COSM_CATEGORY_NAMES
        for c in categories:
            if c.name in legacy_cat:
                await cs.delete(c.id)
                print(f"🗑 Удалена категория: {c.name}")

        print(f"\n✅ Готово. Удалено товаров: {len(to_delete)}")

    await engine.dispose()


if __name__ == "__main__":
    asyncio.run(main())
