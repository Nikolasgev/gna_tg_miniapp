#!/usr/bin/env bash
# Сборка Mini App (Flutter Web) и копирование в backend/static_mini_app для деплоя на Railway.
# Запуск из корня репозитория: ./scripts/build_mini_app_for_railway.sh
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT/frontend"

if ! command -v flutter &>/dev/null; then
  echo "Нужен Flutter SDK: https://docs.flutter.dev/get-started/install"
  exit 1
fi

flutter pub get
flutter build web --release \
  --target lib/mini_app/main.dart \
  --dart-define=API_BASE_URL=SAME_ORIGIN \
  --dart-define=ENVIRONMENT=production

cd "$ROOT"
rm -rf backend/static_mini_app
cp -r frontend/build/web backend/static_mini_app
echo "Готово: backend/static_mini_app (закоммитьте и задеплойте Railway)."
echo "В CORS_ORIGINS добавьте https://<ваш-домен>.up.railway.app если ещё нет."
