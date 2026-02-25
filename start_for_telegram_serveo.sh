#!/bin/bash
# Скрипт для быстрого запуска Mini App для тестирования в Telegram (с Serveo)

set -e

# Цвета
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}════════════════════════════════════════════════${NC}"
echo -e "${BLUE}🚀 Запуск Mini App для Telegram (Serveo)${NC}"
echo -e "${BLUE}════════════════════════════════════════════════${NC}"
echo ""

# Проверка SSH
if ! command -v ssh &> /dev/null; then
    echo -e "${RED}❌ SSH не установлен!${NC}"
    exit 1
fi

# Проверка Flutter
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}❌ Flutter не установлен!${NC}"
    exit 1
fi

# Остановка предыдущих процессов
echo -e "${YELLOW}🛑 Остановка предыдущих процессов...${NC}"
pkill -f "uvicorn app.main:app" 2>/dev/null || true
pkill -f "ssh.*serveo" 2>/dev/null || true
pkill -f "python3 -m http.server" 2>/dev/null || true
sleep 2

# Запуск backend
echo -e "${GREEN}📦 Запуск backend на порту 8000...${NC}"
cd backend
if [ ! -d "venv" ]; then
    echo -e "${RED}❌ Виртуальное окружение не найдено!${NC}"
    echo "Создайте его: python3.11 -m venv venv"
    exit 1
fi

source venv/bin/activate
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000 > /tmp/backend.log 2>&1 &
BACKEND_PID=$!
cd ..
sleep 3

# Проверка backend
if ! curl -s http://localhost:8000/api/v1/businesses/default-business > /dev/null 2>&1; then
    echo -e "${RED}❌ Backend не запустился!${NC}"
    echo "Проверьте логи: tail -f /tmp/backend.log"
    exit 1
fi
echo -e "${GREEN}✅ Backend запущен${NC}"

# Запуск Serveo для backend
echo -e "${GREEN}🌐 Запуск Serveo для backend (порт 8000)...${NC}"
echo -e "${YELLOW}   Это может занять несколько секунд...${NC}"
ssh -o StrictHostKeyChecking=no -o ServerAliveInterval=60 -R 80:localhost:8000 serveo.net > /tmp/serveo_backend.log 2>&1 &
SSH_BACKEND_PID=$!
sleep 10

# Получение URL backend из логов serveo (serveo выводит на stderr; форматы: serveo.net или serveousercontent.com)
BACKEND_URL=$(grep -oE 'https://[a-zA-Z0-9.-]+\.serveo\.net' /tmp/serveo_backend.log 2>/dev/null | head -1 || echo "")
if [ -z "$BACKEND_URL" ]; then
    BACKEND_URL=$(grep -oE 'https://[a-zA-Z0-9.-]+\.serveousercontent\.com' /tmp/serveo_backend.log 2>/dev/null | head -1 || echo "")
fi

if [ -z "$BACKEND_URL" ]; then
    echo -e "${YELLOW}⚠️  Не удалось автоматически получить backend URL${NC}"
    echo -e "${YELLOW}Проверьте логи: tail -f /tmp/serveo_backend.log${NC}"
    echo -e "${YELLOW}Или введите URL вручную:${NC}"
    read -p "Backend URL (https://...serveo.net): " BACKEND_URL
    if [ -z "$BACKEND_URL" ]; then
        echo -e "${RED}❌ Backend URL обязателен!${NC}"
        exit 1
    fi
fi

echo -e "${GREEN}✅ Backend URL: ${BACKEND_URL}${NC}"

# Сборка frontend
echo -e "${GREEN}🔨 Сборка frontend с backend URL: ${BACKEND_URL}...${NC}"
cd frontend
flutter pub get > /dev/null 2>&1

echo -e "${YELLOW}   Сборка может занять несколько минут...${NC}"
flutter build web --release \
  --target lib/mini_app/main.dart \
  --dart-define=API_BASE_URL=${BACKEND_URL} \
  --dart-define=ENVIRONMENT=production > /tmp/flutter_build.log 2>&1

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Ошибка сборки frontend!${NC}"
    echo "Проверьте логи: tail -20 /tmp/flutter_build.log"
    exit 1
fi

echo -e "${GREEN}✅ Frontend собран${NC}"

# Запуск локального сервера для frontend
echo -e "${GREEN}🌐 Запуск frontend на порту 8080...${NC}"
cd build/web
python3 -m http.server 8080 > /tmp/frontend_server.log 2>&1 &
FRONTEND_PID=$!
cd ../../..
sleep 2

# Запуск Serveo для frontend (НЕ останавливаем backend — оба туннеля должны работать!)
# Иначе запросы к API (backend URL) получают 502, т.к. туннель backend был бы закрыт
echo -e "${GREEN}🌐 Запуск Serveo для frontend (порт 8080)...${NC}"
echo -e "${YELLOW}   Backend-туннель остаётся активным для API.${NC}"
ssh -o StrictHostKeyChecking=no -o ServerAliveInterval=60 -R 80:localhost:8080 serveo.net > /tmp/serveo_frontend.log 2>&1 &
SSH_FRONTEND_PID=$!
sleep 10

# Получение URL frontend из логов serveo
FRONTEND_URL=$(grep -oE 'https://[a-zA-Z0-9.-]+\.serveo\.net' /tmp/serveo_frontend.log 2>/dev/null | head -1 || echo "")
if [ -z "$FRONTEND_URL" ]; then
    FRONTEND_URL=$(grep -oE 'https://[a-zA-Z0-9.-]+\.serveousercontent\.com' /tmp/serveo_frontend.log 2>/dev/null | head -1 || echo "")
fi

if [ -z "$FRONTEND_URL" ]; then
    echo -e "${YELLOW}⚠️  Не удалось автоматически получить frontend URL${NC}"
    echo -e "${YELLOW}Проверьте логи: tail -f /tmp/serveo_frontend.log${NC}"
    read -p "Frontend URL (https://...serveo.net): " FRONTEND_URL
    if [ -z "$FRONTEND_URL" ]; then
        echo -e "${RED}❌ Frontend URL обязателен!${NC}"
        exit 1
    fi
fi

echo ""
echo -e "${BLUE}════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ Всё запущено!${NC}"
echo -e "${BLUE}════════════════════════════════════════════════${NC}"
echo ""
echo -e "${GREEN}📍 URLs:${NC}"
echo -e "  Backend:  ${BACKEND_URL}"
echo -e "  Frontend: ${FRONTEND_URL}"
echo ""
echo -e "${YELLOW}📝 Настройте в @BotFather:${NC}"
echo -e "  1. Откройте @BotFather в Telegram"
echo -e "  2. Отправьте /newapp (или /myapps если уже создан)"
echo -e "  3. Выберите вашего бота"
echo -e "  4. Укажите Web App URL: ${FRONTEND_URL}"
echo ""
echo -e "${YELLOW}⚠️  Для остановки нажмите Ctrl+C${NC}"
echo ""

# Функция очистки при выходе
cleanup() {
    echo ""
    echo -e "${YELLOW}🛑 Остановка процессов...${NC}"
    kill $BACKEND_PID 2>/dev/null || true
    kill $SSH_BACKEND_PID 2>/dev/null || true
    kill $SSH_FRONTEND_PID 2>/dev/null || true
    pkill -f "ssh.*serveo" 2>/dev/null || true
    pkill -f "python3 -m http.server" 2>/dev/null || true
    echo -e "${GREEN}✅ Все процессы остановлены${NC}"
    exit 0
}

trap cleanup SIGINT SIGTERM

# Ждем завершения
wait
