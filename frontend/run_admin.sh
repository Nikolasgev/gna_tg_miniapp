#!/bin/bash
# Скрипт для быстрого запуска Admin Panel

cd "$(dirname "$0")"

# Определяем IP-адрес (для Telegram WebView)
# Можно переопределить через переменную окружения API_BASE_URL
if [ -z "$API_BASE_URL" ]; then
  # Пытаемся определить IP автоматически
  if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    IP=$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null || echo "localhost")
  else
    # Linux
    IP=$(hostname -I | awk '{print $1}' 2>/dev/null || echo "localhost")
  fi
  
  # Если IP не найден, используем localhost
  if [ -z "$IP" ] || [ "$IP" == "" ]; then
    API_BASE_URL="http://localhost:8000"
  else
    API_BASE_URL="http://$IP:8000"
  fi
fi

echo "🚀 Запуск Admin Panel..."
echo "📍 Backend URL: $API_BASE_URL"
echo ""

# Проверяем наличие Flutter
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter не найден. Установите Flutter SDK."
    exit 1
fi

# Запускаем приложение
flutter run -d chrome \
  --dart-define=API_BASE_URL=$API_BASE_URL \
  --target=lib/admin_panel/main.dart
