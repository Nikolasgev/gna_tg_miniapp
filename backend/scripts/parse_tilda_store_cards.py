#!/usr/bin/env python3
"""
Вытаскивает из HTML витрины Tilda карточки: data-product-img, название, артикул.

  python scripts/parse_tilda_store_cards.py saved_page.html

Вставьте в файл фрагмент с блоками .js-product (как из DevTools).
"""
import json
import re
import sys
from pathlib import Path


def main() -> None:
    if len(sys.argv) < 2:
        print("Использование: python scripts/parse_tilda_store_cards.py <file.html>")
        sys.exit(1)
    raw = Path(sys.argv[1]).read_text(encoding="utf-8", errors="replace")
    # Карточки: блок от js-product до закрывающего </div> верхнего уровня — грубо режем по паттерну
    chunks = re.split(r'(?=<div class="js-product)', raw)
    out: list[dict[str, str]] = []
    for ch in chunks:
        if "js-product" not in ch:
            continue
        img_m = re.search(r'data-product-img="([^"]+)"', ch)
        if not img_m:
            img_m = re.search(r'data-original="(https://static\.tildacdn\.com[^"]+)"', ch)
        name_m = re.search(
            r'js-store-prod-name[^>]*>([^<]+)</div>',
            ch,
        )
        sku_m = re.search(
            r'js-product-sku[^>]*>([^<]+)</span>',
            ch,
        )
        if not img_m:
            continue
        out.append(
            {
                "image_url": img_m.group(1).strip(),
                "name": (name_m.group(1).strip() if name_m else ""),
                "sku": (sku_m.group(1).strip() if sku_m else ""),
            }
        )
    print(json.dumps(out, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
