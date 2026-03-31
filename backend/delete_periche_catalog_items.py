#!/usr/bin/env python3
"""
Удаляет из default-business товары по SKU и категорию по имени (без полного ресидa).

    export DATABASE_URL="postgresql://..."
    python delete_periche_catalog_items.py

Список ниже — синхронизируйте с правками в app/data/periche_catalog.py.
"""
from __future__ import annotations

import asyncio
import os
import sys

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine
from sqlalchemy.orm import sessionmaker

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from app.models.business import Business
from app.models.category import Category
from app.models.product import Product
from app.services.category_service import CategoryService
from app.services.product_service import ProductService

BUSINESS_SLUG = "default-business"

# Удалить товары (SKU)
SKUS_TO_DELETE = frozenset(
    {
        "PERICHE-SPREM",
        "PERICHE-SPREM-LI",
        "PERICHE-KOVOLM",
        "PERICHE-KOAVOLM",
    }
)

# Удалить категорию по имени (после товаров; должна быть пуста по связям)
CATEGORY_NAME_TO_DELETE = "KODE VOLUME"


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
        products = list(rp.scalars().all())

        deleted_p = 0
        for p in products:
            if p.sku and p.sku in SKUS_TO_DELETE:
                await product_service.delete(p.id)
                print(f"🗑 Товар: {p.title} ({p.sku})")
                deleted_p += 1

        stmt_c = select(Category).where(
            Category.business_id == business.id,
            Category.name == CATEGORY_NAME_TO_DELETE,
        )
        rc = await db.execute(stmt_c)
        cat = rc.scalar_one_or_none()
        if cat:
            ok = await category_service.delete(cat.id)
            if ok:
                print(f"🗑 Категория: {CATEGORY_NAME_TO_DELETE}")
            else:
                print(f"⚠️  Не удалось удалить категорию {CATEGORY_NAME_TO_DELETE}")
        else:
            print(f"ℹ️  Категория '{CATEGORY_NAME_TO_DELETE}' не найдена")

        print(f"\n✅ Удалено товаров: {deleted_p}")

    await engine.dispose()


if __name__ == "__main__":
    asyncio.run(main())
