#!/bin/bash
# Запуск Mini App через ОДИН туннель Cloudflare (frontend раздаётся с backend)
# Используйте, если ngrok заблокирован по IP (ERR_NGROK_9040)

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}════════════════════════════════════════════════${NC}"
echo -e "${BLUE}🚀 Mini App для Telegram (Cloudflare, 1 туннель)${NC}"
echo -e "${BLUE}════════════════════════════════════════════════${NC}"
echo ""

if ! command -v cloudflared &> /dev/null; then
    echo -e "${RED}❌ cloudflared не установлен! brew install cloudflared${NC}"
    exit 1
fi

if ! command -v flutter &> /dev/null; then
    echo -e "${RED}❌ Flutter не установлен!${NC}"
    exit 1
fi

echo -e "${YELLOW}🛑 Остановка предыдущих процессов...${NC}"
pkill -f "uvicorn app.main:app" 2>/dev/null || true
pkill -f "cloudflared tunnel" 2>/dev/null || true
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

echo -e "${GREEN}🌐 Запуск Cloudflare Tunnel (127.0.0.1)...${NC}"
> /tmp/cloudflared_single.log
# 127.0.0.1 вместо localhost — меньше проблем с DNS; --retries для устойчивости к 502
cloudflared tunnel --url http://127.0.0.1:8000 --retries 10 >> /tmp/cloudflared_single.log 2>&1 &
CF_PID=$!
sleep 10

URL=$(grep -oE 'https://[a-z0-9-]+\.trycloudflare\.com' /tmp/cloudflared_single.log 2>/dev/null | head -1)
if [ -z "$URL" ]; then
    sleep 4
    URL=$(grep -oE 'https://[a-z0-9-]+\.trycloudflare\.com' /tmp/cloudflared_single.log 2>/dev/null | head -1)
fi
if [ -z "$URL" ]; then
    echo -e "${RED}❌ Не удалось получить URL. tail -30 /tmp/cloudflared_single.log${NC}"
    kill $BACKEND_PID 2>/dev/null
    kill $CF_PID 2>/dev/null
    exit 1
fi

echo ""
echo -e "${BLUE}════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ Запущено. Один туннель: frontend + API${NC}"
echo -e "${BLUE}════════════════════════════════════════════════${NC}"
echo ""
echo -e "${GREEN}📍 URL для Web App: ${URL}${NC}"
echo ""
echo -e "${YELLOW}📝 @BotFather → Edit Bot → Web App URL: ${URL}${NC}"
echo -e "${YELLOW}⚠️  Не закрывайте терминал. Ctrl+C для остановки.${NC}"
echo ""

cleanup() {
    echo ""
    echo -e "${YELLOW}🛑 Остановка...${NC}"
    kill $BACKEND_PID 2>/dev/null || true
    kill $CF_PID 2>/dev/null || true
    pkill -f "cloudflared tunnel" 2>/dev/null || true
    echo -e "${GREEN}✅ Остановлено${NC}"
    exit 0
}
trap cleanup SIGINT SIGTERM

while true; do sleep 60; done
