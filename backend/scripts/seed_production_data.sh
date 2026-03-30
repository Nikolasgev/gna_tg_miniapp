#!/usr/bin/env bash
# Заполнение production БД: бизнес default-business + демо-категории и товары.
#
# ВАЖНО: Postgres (и желательно Redis) на Railway должны быть Online.
#
# С Mac нельзя использовать postgres.railway.internal — возьмите ПУБЛИЧНЫЙ URL:
#   Railway → сервис Postgres → Connect / Variables → публичный host (proxy.rlwy.net и т.п.)
#
# Использование:
#   cd backend
#   source venv/bin/activate   # pip install -r requirements.txt при необходимости
#   export DATABASE_URL='…'   # целиком из Railway → Postgres → Connect → Public Network (порт — число, не слово PORT)
#   ./scripts/seed_production_data.sh
#
set -euo pipefail
cd "$(dirname "$0")/.."

if [[ -z "${DATABASE_URL:-}" ]]; then
  echo "Ошибка: задайте DATABASE_URL (публичный Postgres URL из Railway)."
  exit 1
fi

# Пример из доки с буквальными USER/PASS/HOST/PORT даёт ValueError: invalid literal for int(): 'PORT'
if [[ "$DATABASE_URL" == *':PORT/'* ]] || [[ "$DATABASE_URL" == 'postgresql://USER:'* ]] || [[ "$DATABASE_URL" == *'@HOST:'* ]]; then
  echo "Ошибка: в DATABASE_URL остались слова-заглушки (USER, PASS, HOST, PORT)."
  echo "Откройте Railway → Postgres → Connect → скопируйте полный URL (публичный хост, порт числом, например :5432)."
  exit 1
fi

echo "==> 1/2 create_production_business.py"
python create_production_business.py

echo ""
echo "==> 2/2 create_demo_menu.py"
python create_demo_menu.py

echo ""
echo "Готово. Перезапустите сервис gna_tg_miniapp в Railway (или подождите), чтобы сбросить кэш Redis."
