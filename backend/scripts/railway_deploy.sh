#!/usr/bin/env bash
# Деплой API на Railway из каталога backend (запускать у себя в терминале).
# Перед первым запуском: railway login
# При необходимости задайте: RAILWAY_PROJECT, RAILWAY_SERVICE (имена в Dashboard).
set -euo pipefail
cd "$(dirname "$0")/.."

echo "==> $(pwd)"
railway whoami

if [[ ! -f .railway/config.json ]]; then
  echo "==> Нет привязки к проекту — railway link"
  railway link -p "${RAILWAY_PROJECT:-capable-tenderness}" -s "${RAILWAY_SERVICE:-gna_tg_miniapp}"
fi

railway status

echo "==> railway up (сборка Dockerfile + деплой)"
echo "    Миграции: см. preDeployCommand в railway.json (выполняются на Railway, не с Mac)."
railway up

echo "==> Готово. Проверьте /health и в Deploy logs этап Pre-deploy (alembic)."
