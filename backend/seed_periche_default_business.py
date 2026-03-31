#!/usr/bin/env python3
"""
Полностью очищает каталог default-business и создаёт товары Periche (как на сайте).
Два объёма: меньший дешевле, больший дороже на реалистичную доплату (см. periche_pricing).

    export DATABASE_URL="postgresql://..."
    python seed_periche_default_business.py

После — перезапуск сервиса на Railway (кэш Redis).
"""
from __future__ import annotations

import asyncio
import os
import random
import sys

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine
from sqlalchemy.orm import sessionmaker

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from app.data.periche_catalog import PERICHE_CATEGORIES_DATA, PERICHE_PRODUCTS_DATA
from app.data.periche_pricing import single_price, two_volume_prices
from app.models.business import Business
from app.models.category import Category
from app.models.product import Product
from app.services.category_service import CategoryService
from app.services.product_service import ProductService


BUSINESS_SLUG = "default-business"
RNG_SEED = 20260402


def _normalize_db_url(raw: str) -> str:
    if raw.startswith("postgresql://") and "+asyncpg" not in raw:
        return raw.replace("postgresql://", "postgresql+asyncpg://", 1)
    return raw


async def main() -> None:
    raw = os.getenv("DATABASE_URL")
    if not raw:
        print("❌ Задайте DATABASE_URL")
        sys.exit(1)
    url = _normalize_db_url(raw)

    rng = random.Random(RNG_SEED)

    engine = create_async_engine(url, echo=False)
    async_session = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)

    async with async_session() as db:
        stmt_b = select(Business).where(Business.slug == BUSINESS_SLUG)
        r = await db.execute(stmt_b)
        business = r.scalar_one_or_none()
        if not business:
            print(f"❌ Бизнес '{BUSINESS_SLUG}' не найден")
            await engine.dispose()
            sys.exit(1)

        product_service = ProductService(db)
        category_service = CategoryService(db)

        stmt_p = select(Product).where(Product.business_id == business.id)
        rp = await db.execute(stmt_p)
        old_products = list(rp.scalars().all())
        for p in old_products:
            await product_service.delete(p.id)
            print(f"🗑 Удалён товар: {p.title} ({p.sku})")

        stmt_c = select(Category).where(Category.business_id == business.id)
        rc = await db.execute(stmt_c)
        old_cats = list(rc.scalars().all())
        for c in old_cats:
            await category_service.delete(c.id)
            print(f"🗑 Удалена категория: {c.name}")

        created_categories: dict[str, Category] = {}
        for cat_data in PERICHE_CATEGORIES_DATA:
            cat = await category_service.create(
                business_id=business.id,
                name=cat_data["name"],
                position=cat_data["position"],
                surcharge=cat_data["surcharge"],
            )
            created_categories[cat.name] = cat
            print(f"✅ Категория: {cat.name}")

        for pd in PERICHE_PRODUCTS_DATA:
            kind = pd["volume_kind"]
            if kind == "500_1000":
                base, variations = two_volume_prices(rng, ("500 мл", "1000 мл"))
            elif kind == "75_500":
                base, variations = two_volume_prices(rng, ("75 мл", "500 мл"))
            elif kind == "single_100":
                base, variations = single_price(rng)
            else:
                base, variations = single_price(rng)

            cat = created_categories[pd["category"]]
            await product_service.create(
                business_id=business.id,
                title=pd["title"],
                description=pd.get("description"),
                price=base,
                currency="RUB",
                sku=pd["sku"],
                image_url=pd.get("image_url"),
                variations=variations,
                category_ids=[cat.id],
            )
            vol_info = f"варианты {variations}" if variations else f"цена {base}"
            print(f"✅ {pd['title']} — {vol_info}")

        print(f"\n✅ Каталог Periche для {BUSINESS_SLUG} готов ({len(PERICHE_PRODUCTS_DATA)} товаров).")

    await engine.dispose()


if __name__ == "__main__":
    asyncio.run(main())
