#!/usr/bin/env python3
"""
Проставляет image_url товарам HAIR-*.

Приоритет:
1) image_url из hair_cosmetics_catalog (например Periche / Tilda static.tildacdn.com)
2) «старые» товары в БД: совпадение названия → категория → общий пул uploads/https
3) HAIR_FALLBACK_STOCK_URLS, если доноров нет

    export DATABASE_URL="postgresql://..."
    python sync_hair_catalog_images.py
"""
from __future__ import annotations

import asyncio
import os
import sys
from collections import defaultdict

from sqlalchemy import and_, not_, or_, select
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine
from sqlalchemy.orm import selectinload, sessionmaker

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from app.data.hair_cosmetics_catalog import (
    HAIR_COSMETICS_PRODUCTS_DATA,
    HAIR_FALLBACK_STOCK_URLS,
)
from app.models.product import Product
from app.services.business_service import BusinessService
from app.services.product_service import ProductService


TARGET_SLUGS = ("default-business", "hair-cosmetics")

UPLOAD_PREFIX = "/api/v1/images/uploads/"

# Ключевые слова в названиях категорий доноров → целевая категория каталога
_CATEGORY_KEYWORDS: dict[str, tuple[str, ...]] = {
    "Шампуни": ("шампун",),
    "Кондиционеры": ("кондицион",),
    "Маски для волос": ("маск",),
    "Масла и сыворотки": ("масл", "сыворот"),
    "Средства для укладки": ("укладк", "лак", "спрей", "мусс", "пена", "фиксац"),
    "Окрашивание": ("окраш", "краск", "окисл", "блонд", "тонир", "осветл"),
}


def _normalize_db_url(raw: str) -> str:
    if raw.startswith("postgresql://") and "+asyncpg" not in raw:
        return raw.replace("postgresql://", "postgresql+asyncpg://", 1)
    return raw


def _donor_category_blob(cats: list) -> str:
    return " ".join(c.name.lower() for c in (cats or []) if getattr(c, "name", None))


def _pool_for_target_category(
    target_cat: str,
    donors_by_blob: list[tuple[str, str]],
) -> list[str]:
    """Список уникальных image_url доноров, чьи категории подходят под target_cat."""
    keywords = _CATEGORY_KEYWORDS.get(target_cat, ())
    if not keywords:
        return []
    seen: set[str] = set()
    out: list[str] = []
    for blob, url in donors_by_blob:
        if any(kw in blob for kw in keywords) and url not in seen:
            seen.add(url)
            out.append(url)
    return out


async def _load_image_donors(db: AsyncSession) -> list[Product]:
    """Товары с реальными картинками: загрузки на сервер или старые https (без unsplash)."""
    stmt = (
        select(Product)
        .options(selectinload(Product.categories))
        .where(Product.image_url.isnot(None))
        .where(
            or_(
                Product.image_url.like(f"{UPLOAD_PREFIX}%"),
                and_(
                    Product.image_url.like("https%"),
                    not_(Product.image_url.ilike("%unsplash%")),
                ),
            )
        )
    )
    r = await db.execute(stmt)
    return list(r.scalars().unique().all())


async def main() -> None:
    raw = os.getenv("DATABASE_URL")
    if not raw:
        print("❌ Задайте DATABASE_URL")
        sys.exit(1)
    url = _normalize_db_url(raw)

    sku_to_catalog = {p["sku"]: p for p in HAIR_COSMETICS_PRODUCTS_DATA if p.get("sku")}
    catalog_has_all_images = all(p.get("image_url") for p in HAIR_COSMETICS_PRODUCTS_DATA)

    engine = create_async_engine(url, echo=False)
    async_session = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)

    async with async_session() as db:
        title_to_url: dict[str, str] = {}
        donors_by_blob: list[tuple[str, str]] = []
        fallback_urls: list[str] = []

        if catalog_has_all_images:
            print("ℹ️  У всех позиций каталога задан image_url — доноры из БД не запрашиваем.")
        else:
            all_donor_candidates = await _load_image_donors(db)

            donors = [p for p in all_donor_candidates if p.sku and not str(p.sku).startswith("HAIR-")]
            if not donors:
                donors = list(all_donor_candidates)

            if donors:
                for p in donors:
                    t = (p.title or "").strip().lower()
                    if t:
                        title_to_url[t] = p.image_url or ""

                for p in donors:
                    blob = _donor_category_blob(list(p.categories))
                    u = p.image_url
                    if u:
                        donors_by_blob.append((blob, u))

                seen_f: set[str] = set()
                for _, u in donors_by_blob:
                    if u not in seen_f:
                        seen_f.add(u)
                        fallback_urls.append(u)
            else:
                print(
                    "⚠️  В базе нет доноров (uploads или https без unsplash). "
                    "Подставляю HAIR_FALLBACK_STOCK_URLS — потом замените фото через админку или "
                    "add_cosmetic_products.py / add_mask_products.py."
                )
                fallback_urls = list(HAIR_FALLBACK_STOCK_URLS)

        business_service = BusinessService(db)
        product_service = ProductService(db)
        total = 0

        for slug in TARGET_SLUGS:
            business = await business_service.get_by_slug(slug)
            if not business:
                print(f"⚠️  Бизнес '{slug}' не найден, пропуск")
                continue

            products = await product_service.get_by_business_slug(slug, include_inactive=True)
            hair_products = [p for p in products if p.sku and str(p.sku).startswith("HAIR-")]
            rr: dict[str, int] = defaultdict(int)

            for prod in sorted(hair_products, key=lambda x: (x.sku or "")):
                cat = sku_to_catalog.get(prod.sku or "", {}).get("category")
                if not cat:
                    continue

                new_url: str | None = None
                cat_entry = sku_to_catalog.get(prod.sku or "")
                if cat_entry and cat_entry.get("image_url"):
                    new_url = cat_entry["image_url"]

                if not new_url:
                    tkey = (prod.title or "").strip().lower()
                    if tkey and tkey in title_to_url:
                        new_url = title_to_url[tkey]

                if not new_url:
                    pool = _pool_for_target_category(cat, donors_by_blob)
                    if not pool:
                        pool = fallback_urls
                    if pool:
                        i = rr[cat] % len(pool)
                        rr[cat] += 1
                        new_url = pool[i]

                if not new_url:
                    print(f"⚠️  {slug} / {prod.sku}: не удалось подобрать картинку")
                    continue

                if prod.image_url == new_url:
                    continue
                await product_service.update(prod.id, image_url=new_url)
                print(f"✅ {slug} / {prod.sku} ← {new_url}")
                total += 1

        print(f"\n📷 Обновлено записей: {total}")

    await engine.dispose()


if __name__ == "__main__":
    try:
        asyncio.run(main())
    except OSError as e:
        if "Connect call failed" in str(e) or "connection refused" in str(e).lower():
            print(
                "❌ Не удаётся подключиться к PostgreSQL. Запустите БД (например: "
                "`docker compose up -d postgres` в корне проекта) или задайте рабочий DATABASE_URL."
            )
            sys.exit(1)
        raise
