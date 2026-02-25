# Инструкция по запуску и тестированию

## Предварительные требования

1. **Flutter SDK** (версия 3.9.2 или выше)
2. **Python 3.11+** (для backend)
3. **PostgreSQL** (для базы данных)
4. **Redis** (опционально, для кеширования)

## Шаг 1: Запуск Backend

### Вариант A: Локальный запуск (рекомендуется для разработки)

1. Перейдите в директорию backend:
```bash
cd backend
```

2. Создайте виртуальное окружение (если еще не создано):
```bash
python3.11 -m venv venv
source venv/bin/activate  # На macOS/Linux
# или
venv\Scripts\activate  # На Windows
```

3. Установите зависимости:
```bash
pip install -r requirements.txt
```

4. Настройте переменные окружения:
```bash
# Создайте файл .env или скопируйте из .env.example
cp .env.example .env
# Отредактируйте .env и укажите DATABASE_URL
```

5. Запустите базу данных (если еще не запущена):
```bash
# Через Docker (если установлен):
docker run -d --name postgres -p 5432:5432 -e POSTGRES_PASSWORD=postgres postgres:15-alpine
docker run -d --name redis -p 6379:6379 redis:7-alpine

# Или используйте локально установленный PostgreSQL
```

6. Примените миграции базы данных:
```bash
alembic upgrade head
```

7. Создайте тестового пользователя админки (если нужно):
```bash
export DATABASE_URL="postgresql://user:password@localhost:5432/dbname"
python create_admin_user.py \
  --username admin \
  --password admin123 \
  --business-name "Test Business" \
  --business-slug test-business \
  --email admin@test.com
```

8. Запустите сервер:
```bash
# Используйте скрипт:
./run_local.sh

# Или напрямую:
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Backend будет доступен по адресу: `http://localhost:8000`

### Вариант B: Запуск через Docker

```bash
cd backend
docker-compose up -d
```

## Шаг 2: Настройка Frontend

1. Перейдите в директорию frontend:
```bash
cd frontend
```

2. Установите зависимости:
```bash
flutter pub get
```

3. Определите IP-адрес вашего компьютера (для доступа из Telegram WebView):
```bash
# На macOS/Linux:
ifconfig | grep "inet " | grep -v 127.0.0.1

# Или используйте:
ipconfig getifaddr en0  # macOS
hostname -I  # Linux
```

**Важно:** Telegram WebView не может обращаться к `localhost`, поэтому нужно использовать IP-адрес вашей машины в локальной сети.

## Шаг 3: Запуск Admin Panel

### Для веб-браузера (рекомендуется для тестирования админки):

```bash
cd frontend

# Запуск с указанием API URL (замените YOUR_IP на ваш IP-адрес):
flutter run -d chrome \
  --dart-define=API_BASE_URL=http://YOUR_IP:8000 \
  --target=lib/admin_panel/main.dart
```

Или если backend на localhost:
```bash
flutter run -d chrome \
  --dart-define=API_BASE_URL=http://localhost:8000 \
  --target=lib/admin_panel/main.dart
```

### Для мобильного устройства/эмулятора:

```bash
flutter run \
  --dart-define=API_BASE_URL=http://YOUR_IP:8000 \
  --target=lib/admin_panel/main.dart
```

## Шаг 4: Тестирование Admin Panel

1. **Откройте приложение** в браузере или на устройстве

2. **Войдите в систему:**
   - Логин: `admin` (или тот, который вы создали)
   - Пароль: `admin123` (или тот, который вы указали при создании)

3. **Проверьте функциональность:**
   - ✅ Вход в систему
   - ✅ Просмотр дашборда
   - ✅ Управление продуктами
   - ✅ Управление категориями
   - ✅ Управление промокодами
   - ✅ Настройки бизнеса
   - ✅ Аналитика

## Шаг 5: Запуск Mini App (Telegram Mini App)

```bash
cd frontend

# Для веб (можно открыть в браузере):
flutter run -d chrome \
  --dart-define=API_BASE_URL=http://YOUR_IP:8000 \
  --target=lib/mini_app/main.dart

# Для мобильного устройства:
flutter run \
  --dart-define=API_BASE_URL=http://YOUR_IP:8000 \
  --target=lib/mini_app/main.dart
```

## Быстрый запуск (скрипт)

Создайте скрипт `run_admin.sh` в корне проекта:

```bash
#!/bin/bash
cd frontend
flutter run -d chrome \
  --dart-define=API_BASE_URL=http://localhost:8000 \
  --target=lib/admin_panel/main.dart
```

Сделайте его исполняемым:
```bash
chmod +x run_admin.sh
```

Запустите:
```bash
./run_admin.sh
```

## Проверка подключения к Backend

Проверьте, что backend доступен:
```bash
curl http://localhost:8000/api/v1/health
# или
curl http://YOUR_IP:8000/api/v1/health
```

## Устранение проблем

### Backend не запускается
- Проверьте, что PostgreSQL запущен
- Проверьте переменные окружения в `.env`
- Убедитесь, что порт 8000 свободен

### Frontend не может подключиться к Backend
- Убедитесь, что backend запущен и доступен
- Проверьте IP-адрес в `--dart-define=API_BASE_URL=...`
- Для Telegram WebView используйте IP-адрес, а не localhost
- Проверьте firewall настройки

### Ошибки авторизации
- Убедитесь, что пользователь создан в базе данных
- Проверьте логи backend для деталей ошибки
- Убедитесь, что токен сохраняется правильно

## Полезные команды

### Проверка Flutter окружения:
```bash
flutter doctor
```

### Очистка и пересборка:
```bash
cd frontend
flutter clean
flutter pub get
flutter run
```

### Просмотр логов backend:
```bash
# Логи будут в консоли, где запущен uvicorn
```

### Тестирование API напрямую:
```bash
# Проверка health endpoint
curl http://localhost:8000/api/v1/health

# Вход в админку
curl -X POST http://localhost:8000/api/v1/admin/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}'
```
