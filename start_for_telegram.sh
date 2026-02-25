#!/bin/bash
# Скрипт для быстрого запуска Mini App для тестирования в Telegram
# Использует ДВА туннеля Cloudflare одновременно (backend + frontend), чтобы API работал

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}════════════════════════════════════════════════${NC}"
echo -e "${BLUE}🚀 Запуск Mini App для Telegram (2 туннеля)${NC}"
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
pkill -f "python3 -m http.server" 2>/dev/null || true
pkill -f "ngrok" 2>/dev/null || true
sleep 2

echo -e "${GREEN}📦 Запуск backend на порту 8000...${NC}"
cd "$(dirname "$0")/backend"
[ ! -d "venv" ] && { echo -e "${RED}❌ venv не найден. Создайте: python3 -m venv venv${NC}"; exit 1; }
source venv/bin/activate
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000 > /tmp/backend.log 2>&1 &
BACKEND_PID=$!
cd ..
sleep 4

if ! curl -s http://localhost:8000/health > /dev/null 2>&1; then
    echo -e "${RED}❌ Backend не запустился. Логи: tail -20 /tmp/backend.log${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Backend запущен${NC}"

echo -e "${GREEN}🌐 Туннель 1: backend (порт 8000)...${NC}"
> /tmp/cloudflared_backend.log
cloudflared tunnel --url http://localhost:8000 >> /tmp/cloudflared_backend.log 2>&1 &
CF_BACKEND_PID=$!
sleep 6
BACKEND_URL=$(grep -oE 'https://[a-z0-9-]+\.trycloudflare\.com' /tmp/cloudflared_backend.log 2>/dev/null | head -1)
if [ -z "$BACKEND_URL" ]; then
    sleep 4
    BACKEND_URL=$(grep -oE 'https://[a-z0-9-]+\.trycloudflare\.com' /tmp/cloudflared_backend.log 2>/dev/null | head -1)
fi
if [ -z "$BACKEND_URL" ]; then
    echo -e "${RED}❌ Не удалось получить backend URL. Логи: tail -30 /tmp/cloudflared_backend.log${NC}"
    kill $BACKEND_PID 2>/dev/null; kill $CF_BACKEND_PID 2>/dev/null
    exit 1
fi
echo -e "${GREEN}✅ Backend URL: ${BACKEND_URL}${NC}"

echo -e "${GREEN}🔨 Сборка frontend (API → ${BACKEND_URL})...${NC}"
cd frontend
flutter pub get > /dev/null 2>&1
flutter build web --release \
  --target lib/mini_app/main.dart \
  --dart-define=API_BASE_URL=${BACKEND_URL} \
  --dart-define=ENVIRONMENT=production > /tmp/flutter_build.log 2>&1 || {
    echo -e "${RED}❌ Ошибка сборки. tail -30 /tmp/flutter_build.log${NC}"
    kill $BACKEND_PID 2>/dev/null; kill $CF_BACKEND_PID 2>/dev/null
    exit 1
}
echo -e "${GREEN}✅ Frontend собран${NC}"

echo -e "${GREEN}🌐 Запуск frontend на порту 8080...${NC}"
cd build/web
python3 -m http.server 8080 > /tmp/frontend_server.log 2>&1 &
FRONTEND_PID=$!
cd ../../..
sleep 2

echo -e "${GREEN}🌐 Туннель 2: frontend (порт 8080)...${NC}"
> /tmp/cloudflared_frontend.log
cloudflared tunnel --url http://localhost:8080 >> /tmp/cloudflared_frontend.log 2>&1 &
CF_FRONTEND_PID=$!
sleep 6
FRONTEND_URL=$(grep -oE 'https://[a-z0-9-]+\.trycloudflare\.com' /tmp/cloudflared_frontend.log 2>/dev/null | head -1)
if [ -z "$FRONTEND_URL" ]; then
    sleep 4
    FRONTEND_URL=$(grep -oE 'https://[a-z0-9-]+\.trycloudflare\.com' /tmp/cloudflared_frontend.log 2>/dev/null | head -1)
fi
if [ -z "$FRONTEND_URL" ]; then
    echo -e "${RED}❌ Не удалось получить frontend URL. tail -30 /tmp/cloudflared_frontend.log${NC}"
fi

echo ""
echo -e "${BLUE}════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ Запущено. Оба туннеля активны.${NC}"
echo -e "${BLUE}════════════════════════════════════════════════${NC}"
echo ""
echo -e "${GREEN}📍 Backend:  ${BACKEND_URL}${NC}"
echo -e "${GREEN}📍 Frontend: ${FRONTEND_URL}${NC}"
echo ""
echo -e "${YELLOW}📝 @BotFather → Web App URL: ${FRONTEND_URL}${NC}"
echo -e "${YELLOW}⚠️  Не закрывайте терминал. Ctrl+C для остановки.${NC}"
echo ""

cleanup() {
    echo ""
    echo -e "${YELLOW}🛑 Остановка...${NC}"
    kill $BACKEND_PID 2>/dev/null || true
    kill $FRONTEND_PID 2>/dev/null || true
    kill $CF_BACKEND_PID 2>/dev/null || true
    kill $CF_FRONTEND_PID 2>/dev/null || true
    pkill -f "cloudflared tunnel" 2>/dev/null || true
    pkill -f "python3 -m http.server 8080" 2>/dev/null || true
    echo -e "${GREEN}✅ Остановлено${NC}"
    exit 0
}
trap cleanup SIGINT SIGTERM

while true; do sleep 60; done
