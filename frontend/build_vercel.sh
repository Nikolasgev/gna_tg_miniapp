#!/bin/bash
set -e
if [ ! -d flutter ]; then
  git clone https://github.com/flutter/flutter.git --depth 1 -b stable
fi
export PATH="$PATH:$(pwd)/flutter/bin"
flutter doctor
flutter pub get
flutter config --enable-web
flutter build web --release \
  --target lib/mini_app/main.dart \
  --dart-define=ENVIRONMENT=production \
  --dart-define=API_BASE_URL="${API_BASE_URL:-https://gnatgminiapp-production.up.railway.app}"
