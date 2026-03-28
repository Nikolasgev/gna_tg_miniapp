#!/usr/bin/env bash
# Проверка доступности API и CORS для Mini App (запускать локально).
# Использование:
#   ./scripts/check_production_readiness.sh
#   BACKEND_URL=https://gnatgminiapp-production.up.railway.app \
#   FRONTEND_ORIGIN=https://nikolasgev.github.io \
#   ./scripts/check_production_readiness.sh

set -euo pipefail

BACKEND_URL="${BACKEND_URL:-https://gnatgminiapp-production.up.railway.app}"
FRONTEND_ORIGIN="${FRONTEND_ORIGIN:-https://nikolasgev.github.io}"
API_PATH="${API_PATH:-/api/v1/businesses/default-business/settings}"

echo "Backend: $BACKEND_URL"
echo "Origin (как у браузера с GitHub Pages): $FRONTEND_ORIGIN"
echo ""

health_raw=$(curl -sS "$BACKEND_URL/health" -w "\n%{http_code}" || printf '\n000')
code_health=$(printf '%s' "$health_raw" | tail -n1)
body_health=$(printf '%s' "$health_raw" | sed '$d')
echo "GET /health -> HTTP $code_health"
if [[ "$code_health" != "200" ]]; then
  if printf '%s' "$body_health" | grep -q "Application not found"; then
    echo "FAIL: Railway отвечает «Application not found» — проверьте BACKEND_URL (сервис удалён, переименован или URL из панели Railway устарел)."
  else
    echo "FAIL: /health не 200. Проверьте Railway, миграции и что приложение поднялось."
  fi
  exit 1
fi

echo ""
echo "OPTIONS preflight (CORS) для $API_PATH ..."
# Браузер шлёт Origin без path репозитория — для GitHub Pages это nikolasgev.github.io
preflight=$(curl -sS -o /dev/null -w "%{http_code}" -X OPTIONS \
  -H "Origin: $FRONTEND_ORIGIN" \
  -H "Access-Control-Request-Method: GET" \
  -H "Access-Control-Request-Headers: content-type,authorization" \
  "$BACKEND_URL$API_PATH" || echo "000")
echo "OPTIONS -> HTTP $preflight"
if [[ "$preflight" != "200" && "$preflight" != "204" ]]; then
  echo "WARN: нестандартный код preflight. Проверьте CORS_ORIGINS в Railway (должен быть https://nikolasgev.github.io или *)."
fi

aco=$(curl -sS -D - -o /dev/null -X OPTIONS \
  -H "Origin: $FRONTEND_ORIGIN" \
  -H "Access-Control-Request-Method: GET" \
  "$BACKEND_URL$API_PATH" 2>/dev/null | grep -i "access-control-allow-origin" || true)
if [[ -z "$aco" ]]; then
  echo "FAIL: нет заголовка Access-Control-Allow-Origin в ответе OPTIONS."
  echo "В Railway задайте CORS_ORIGINS, например:"
  echo '  ["https://nikolasgev.github.io","https://gnatgminiapp-production.up.railway.app"]'
  echo "или временно [\"*\"] для отладки."
  exit 1
fi
echo "OK: $aco"

echo ""
echo "Все быстрые проверки пройдены."
