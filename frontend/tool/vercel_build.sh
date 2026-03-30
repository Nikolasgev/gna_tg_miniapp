#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SDK="$ROOT/.flutter-sdk/bin/flutter"
API="${API_BASE_URL:-https://gnatgminiapp-production.up.railway.app}"
"$SDK" pub get
"$SDK" build web --release --target lib/mini_app/main.dart \
  --dart-define=API_BASE_URL="$API" \
  --dart-define=ENVIRONMENT=production
