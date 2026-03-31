#!/usr/bin/env python3
"""
Пересчитывает цены и variations у существующих товаров PERICHE-* (default-business)
по правилам periche_pricing — без удаления каталога.

    export DATABASE_URL="postgresql://..."
    python update_periche_volume_prices.py
"""
from __future__ import annotations

import asyncio
import os
import random
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine
from sqlalchemy.orm import sessionmaker

from app.data.periche_catalog import PERICHE_PRODUCTS_DATA
from app.data.periche_pricing import single_price, two_volume_prices
from app.models.business import Business
from app.models.product import Product
from app.services.product_service import ProductService


BUSINESS_SLUG = "default-business"
RNG_SEED = 20260402


def _normalize_db_url(raw: str) -> str:
    if raw.startswith("postgresql://") and "+asyncpg" not in raw:
        return raw.replace("postgresql://", "postgresql+asyncpg://", 1)
    return raw


def _pricing_for_sku(sku: str, rng: random.Random):
    meta = next((p for p in PERICHE_PRODUCTS_DATA if p["sku"] == sku), None)
    if not meta:
        return None, None
    kind = meta["volume_kind"]
    if kind == "500_1000":
        return two_volume_prices(rng, ("500 мл", "1000 мл"))
    if kind == "75_500":
        return two_volume_prices(rng, ("75 мл", "500 мл"))
    if kind == "single_100":
        return single_price(rng)
    return single_price(rng)


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

        stmt_p = select(Product).where(
            Product.business_id == business.id,
            Product.sku.like("PERICHE-%"),
        )
        rp = await db.execute(stmt_p)
        products = list(rp.scalars().all())

        ps = ProductService(db)
        n = 0
        for p in products:
            if not p.sku:
                continue
            pair = _pricing_for_sku(p.sku, rng)
            if pair == (None, None):
                continue
            base, variations = pair
            await ps.update(p.id, price=base, variations=variations)
            print(f"✅ {p.title} ({p.sku}): base={base} {variations or ''}")
            n += 1

        print(f"\n📷 Обновлено товаров: {n}")

    await engine.dispose()


if __name__ == "__main__":
    asyncio.run(main())
