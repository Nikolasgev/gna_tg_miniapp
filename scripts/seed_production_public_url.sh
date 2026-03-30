#!/usr/bin/env bash
# Сиды в облачную БД по публичному DATABASE_URL (с Mac / CI).
# Использование:
#   ./scripts/seed_production_public_url.sh 'postgresql://postgres:ПАРОЛЬ@хост:5432/railway'
#
set -euo pipefail
if [[ -z "${1:-}" ]]; then
  echo "Укажите полный DATABASE_URL из Railway → Postgres → Connect (Public)."
  echo "Пример: $0 'postgresql://postgres:xxx@xxxx.proxy.rlwy.net:5432/railway'"
  exit 1
fi

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT/backend"

if [[ -d venv ]]; then
  # shellcheck source=/dev/null
  source venv/bin/activate
fi

export DATABASE_URL="$1"
./scripts/seed_production_data.sh
