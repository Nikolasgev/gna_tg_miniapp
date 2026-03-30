#!/bin/bash

# Скрипт для деплоя фронтенда на Vercel

echo "🚀 Начинаю деплой фронтенда..."

# Переходим в папку фронтенда
cd "$(dirname "$0")"

# Проверяем, что Flutter установлен
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter не установлен!"
    exit 1
fi

# Получаем зависимости
echo "📦 Получаю зависимости..."
flutter pub get

# Собираем Flutter Web
echo "🔨 Собираю Flutter Web..."
flutter build web --target lib/mini_app/main.dart --release \
  --dart-define=API_BASE_URL=https://gnatgminiapp-production.up.railway.app

# Проверяем, что сборка прошла успешно
if [ ! -d "build/web" ]; then
    echo "❌ Ошибка сборки! Папка build/web не найдена."
    exit 1
fi

# Деплоим на Vercel
echo "🚀 Деплою на Vercel..."
cd build/web
npx vercel --prod --yes

echo "✅ Деплой завершен!"














