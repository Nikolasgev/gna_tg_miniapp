"""
Каталог Periche (как на periche.ru): названия, описания, картинки Tilda.
Цены задаёт seed_periche_default_business.py (рандом 1000–3000, два объёма).
"""
from __future__ import annotations

from decimal import Decimal
from typing import Any

from app.data.periche_tilda_reference import (
    FREQ_CONDITIONER_PNG,
    FREQ_SHAMPOO_PNG,
    HEMP_CONDITIONER_PNG,
    HEMP_ENRICHED_OIL_PNG,
    HEMP_SHAMPOO_PNG,
    REISHI_SHAMPOO_PNG,
)

# Категории витрины
PERICHE_CATEGORIES_DATA: list[dict[str, Any]] = [
    {"name": "KODE WET", "position": 1, "surcharge": Decimal("0.00")},
    {"name": "SECRET PLANTS", "position": 2, "surcharge": Decimal("0.00")},
]

# volume_kind: "500_1000" | "75_500" | "single_100"
PERICHE_PRODUCTS_DATA: list[dict[str, Any]] = [
    {
        "title": "FREQ SHAMPOO",
        "description": "Ежедневный увлажняющий шампунь.",
        "sku": "PERICHE-KOFREQ",
        "category": "KODE WET",
        "image_url": FREQ_SHAMPOO_PNG,
        "volume_kind": "500_1000",
    },
    {
        "title": "FREQ CONDITIONER",
        "description": "Ежедневный увлажняющий кондиционер.",
        "sku": "PERICHE-KOAFREQ",
        "category": "KODE WET",
        "image_url": FREQ_CONDITIONER_PNG,
        "volume_kind": "500_1000",
    },
    {
        "title": "HEMP RITUAL SHAMPOO",
        "description": "Увлажняющий шампунь с маслом конопли.",
        "sku": "PERICHE-SPHSH",
        "category": "SECRET PLANTS",
        "image_url": HEMP_SHAMPOO_PNG,
        "volume_kind": "75_500",
    },
    {
        "title": "HEMP RITUAL CONDITIONER",
        "description": "Питательный кондиционер с маслом конопли.",
        "sku": "PERICHE-SPHC",
        "category": "SECRET PLANTS",
        "image_url": HEMP_CONDITIONER_PNG,
        "volume_kind": "75_500",
    },
    {
        "title": "HEMP RITUAL ENRICHED OIL",
        "description": "Конопляное масло для волос.",
        "sku": "PERICHE-SPHO",
        "category": "SECRET PLANTS",
        "image_url": HEMP_ENRICHED_OIL_PNG,
        "volume_kind": "single_100",
    },
    {
        "title": "REISHI RITUAL SHAMPOO",
        "description": "Восстанавливающий шампунь с экстрактом гриба рейши.",
        "sku": "PERICHE-SPRESH",
        "category": "SECRET PLANTS",
        "image_url": REISHI_SHAMPOO_PNG,
        "volume_kind": "75_500",
    },
]
