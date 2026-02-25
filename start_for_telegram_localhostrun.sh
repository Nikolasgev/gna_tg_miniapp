#!/bin/bash
# Запуск Mini App через localhost.run (SSH-туннель, 1 туннель)
# Fallback при 502 Cloudflare или блокировке ngrok

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}════════════════════════════════════════════════${NC}"
echo -e "${BLUE}🚀 Mini App для Telegram (localhost.run)${NC}"
echo -e "${BLUE}════════════════════════════════════════════════${NC}"
echo ""

if ! command -v ssh &> /dev/null; then
    echo -e "${RED}❌ SSH не установлен!${NC}"
    exit 1
fi

if ! command -v flutter &> /dev/null; then
    echo -e "${RED}❌ Flutter не установлен!${NC}"
    exit 1
fi

echo -e "${YELLOW}🛑 Остановка предыдущих процессов...${NC}"
pkill -f "uvicorn app.main:app" 2>/dev/null || true
pkill -f "ssh.*localhost\.run" 2>/dev/null || true
sleep 2

echo -e "${GREEN}🔨 Сборка frontend (SAME_ORIGIN)...${NC}"
cd "$(dirname "$0")/frontend"
flutter pub get > /dev/null 2>&1
flutter build web --release \
  --target lib/mini_app/main.dart \
  --dart-define=API_BASE_URL=SAME_ORIGIN \
  --dart-define=ENVIRONMENT=production > /tmp/flutter_build.log 2>&1 || {
    echo -e "${RED}❌ Ошибка сборки. tail -30 /tmp/flutter_build.log${NC}"
    exit 1
}
echo -e "${GREEN}✅ Frontend собран${NC}"

echo -e "${GREEN}📁 Копирование в backend/static_mini_app...${NC}"
cd ..
rm -rf backend/static_mini_app
cp -r frontend/build/web backend/static_mini_app
echo -e "${GREEN}✅ Готово${NC}"

echo -e "${GREEN}📦 Запуск backend (порт 8000)...${NC}"
cd backend
[ ! -d "venv" ] && { echo -e "${RED}❌ venv не найден. python3 -m venv venv${NC}"; exit 1; }
source venv/bin/activate
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000 > /tmp/backend.log 2>&1 &
BACKEND_PID=$!
cd ..
sleep 4

if ! curl -s http://localhost:8000/health > /dev/null 2>&1; then
    echo -e "${RED}❌ Backend не запустился. tail -20 /tmp/backend.log${NC}"
    kill $BACKEND_PID 2>/dev/null
    exit 1
fi
echo -e "${GREEN}✅ Backend запущен (Mini App на /)${NC}"

echo -e "${GREEN}🌐 Запуск localhost.run (SSH)...${NC}"
> /tmp/localhost_run.log
ssh -o StrictHostKeyChecking=no -o ServerAliveInterval=30 -R 80:127.0.0.1:8000 localhost.run >> /tmp/localhost_run.log 2>&1 &
SSH_PID=$!
sleep 8

# localhost.run выводит URL в формате: https://xxxx.localhost.run
URL=$(grep -oE 'https://[a-zA-Z0-9.-]+\.localhost\.run' /tmp/localhost_run.log 2>/dev/null | head -1)
if [ -z "$URL" ]; then
    sleep 4
    URL=$(grep -oE 'https://[a-zA-Z0-9.-]+\.localhost\.run' /tmp/localhost_run.log 2>/dev/null | head -1)
fi
if [ -z "$URL" ]; then
    # Пробуем другие форматы вывода localhost.run
    URL=$(grep -oE 'https://[a-zA-Z0-9][-a-zA-Z0-9.]*' /tmp/localhost_run.log 2>/dev/null | grep -v cloudflare | head -1)
fi
if [ -z "$URL" ]; then
    echo -e "${YELLOW}⚠️  URL не найден в логах. Проверьте вывод ниже:${NC}"
    tail -15 /tmp/localhost_run.log
    echo ""
    echo -e "${YELLOW}Введите URL вручную (из вывода localhost.run):${NC}"
    read -p "URL: " URL
fi

if [ -n "$URL" ]; then
    echo ""
    echo -e "${BLUE}════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}✅ Запущено${NC}"
    echo -e "${BLUE}════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${GREEN}📍 URL для Web App: ${URL}${NC}"
    echo ""
    echo -e "${YELLOW}📝 @BotFather → Edit Bot → Web App URL: ${URL}${NC}"
fi
echo -e "${YELLOW}⚠️  Не закрывайте терминал. Ctrl+C для остановки.${NC}"
echo ""

cleanup() {
    echo ""
    echo -e "${YELLOW}🛑 Остановка...${NC}"
    kill $BACKEND_PID 2>/dev/null || true
    kill $SSH_PID 2>/dev/null || true
    pkill -f "ssh.*localhost\.run" 2>/dev/null || true
    echo -e "${GREEN}✅ Остановлено${NC}"
    exit 0
}
trap cleanup SIGINT SIGTERM

while true; do sleep 60; done
