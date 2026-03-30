#!/usr/bin/env bash
# Проверка публичного API на Railway (запуск из любой директории).
set -euo pipefail
BASE="${BACKEND_URL:-https://gnatgminiapp-production.up.railway.app}"
echo "Backend: $BASE"

code=$(curl -sS -o /tmp/rw_health.json -w "%{http_code}" \
  --connect-timeout 10 --max-time 20 "$BASE/health" || echo "000")
echo "GET /health -> HTTP $code"
if [[ "$code" != "200" ]]; then
  echo "FAIL"
  exit 1
fi
cat /tmp/rw_health.json
echo ""

code2=$(curl -sS -o /tmp/rw_settings.json -w "%{http_code}" \
  --connect-timeout 10 --max-time 20 \
  "$BASE/api/v1/businesses/default-business/settings" || echo "000")
echo "GET .../default-business/settings -> HTTP $code2"
head -c 400 /tmp/rw_settings.json 2>/dev/null || true
echo ""
if [[ "$code2" == "200" ]]; then
  echo "OK: бизнес default-business найден."
elif [[ "$code2" == "404" ]]; then
  echo "WARN: бизнеса нет — выполните сиды (create_production_business.py и т.д.)."
else
  echo "WARN: неожиданный код (таймаут/ошибка сервера)."
fi

echo ""
echo "Проверка завершена."
