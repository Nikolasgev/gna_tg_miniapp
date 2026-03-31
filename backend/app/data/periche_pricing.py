"""
Цены Periche: «красивые» суммы (1190, 1490, 1990 …), два объёма — меньший дешевле, больший дороже
на разумную доплату из того же набора.
"""
from __future__ import annotations

import random
from decimal import Decimal

# Как в витринах: кончаются на 90 или круглые сотни/тысячи в диапазоне 1000–3000
_NICE_X90: tuple[int, ...] = tuple(range(1090, 3001, 100))  # 1090, 1190, … 2990
_ROUND_HUNDREDS: tuple[int, ...] = (1000, 1500, 2000, 2500, 3000)
NICE_PRICES: tuple[int, ...] = tuple(sorted(set(_NICE_X90 + _ROUND_HUNDREDS)))


def _pick_two_nice_volumes(rng: random.Random) -> tuple[int, int]:
    """Меньший и больший объём — оба из NICE_PRICES, разница ~400–1000 ₽ (или ≥300)."""
    small_candidates = [p for p in NICE_PRICES if p <= 2590]
    p_small = rng.choice(small_candidates)
    candidates = [
        p for p in NICE_PRICES if p > p_small and 400 <= (p - p_small) <= 1000
    ]
    if not candidates:
        candidates = [
            p for p in NICE_PRICES if p > p_small and 300 <= (p - p_small) <= 1200
        ]
    if not candidates:
        candidates = [p for p in NICE_PRICES if p > p_small]
    p_large = rng.choice(candidates)
    return p_small, p_large


def _ml(label: str) -> int:
    return int("".join(c for c in label if c.isdigit()) or 0)


def two_volume_prices(rng: random.Random, labels: tuple[str, str]) -> tuple[Decimal, dict]:
    la, lb = labels
    if _ml(la) > _ml(lb):
        la, lb = lb, la

    p_small, p_large = _pick_two_nice_volumes(rng)

    base = Decimal(p_small)
    variations = {"Объем": {la: 0.0, lb: float(p_large - p_small)}}
    return base, variations


def single_price(rng: random.Random) -> tuple[Decimal, None]:
    p = rng.choice(NICE_PRICES)
    return Decimal(p), None
