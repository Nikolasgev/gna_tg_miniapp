#!/usr/bin/env bash
# Полный локальный цикл: Postgres + Redis (Docker) → миграции → default-business + демо-меню.
# Запуск из корня репозитория: ./scripts/bootstrap_local_stack.sh
#
# Требуется: Docker Desktop запущен, в backend/ есть venv с зависимостями
# (иначе: cd backend && python3 -m venv venv && source venv/bin/activate && pip install -r requirements.txt)
#
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BACKEND="$ROOT/backend"
cd "$BACKEND"

if ! docker info >/dev/null 2>&1; then
  echo "Ошибка: Docker daemon недоступен. Запустите Docker Desktop и повторите."
  exit 1
fi

echo "==> Docker: postgres + redis"
docker compose up -d postgres redis

echo "==> Ожидание Postgres..."
for _ in $(seq 1 40); do
  if docker compose exec -T postgres pg_isready -U postgres >/dev/null 2>&1; then
    echo "Postgres готов."
    break
  fi
  sleep 1
done

if ! docker compose exec -T postgres pg_isready -U postgres >/dev/null 2>&1; then
  echo "Ошибка: Postgres не поднялся за отведённое время."
  exit 1
fi

export DATABASE_URL="postgresql+asyncpg://postgres:postgres@127.0.0.1:5432/tg_store_db"

if [[ -d venv ]]; then
  # shellcheck source=/dev/null
  source venv/bin/activate
fi

echo "==> Alembic upgrade head"
python -m alembic upgrade head

echo "==> Сиды (бизнес + демо-меню)"
./scripts/seed_production_data.sh

echo ""
echo "Готово. Локальная БД заполнена. Запуск API:"
echo "  cd backend && source venv/bin/activate && uvicorn app.main:app --reload"
echo "  или: docker compose up backend"
