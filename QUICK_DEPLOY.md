# Быстрая инструкция по деплою для демонстрации

## 🚀 Минимальные шаги для деплоя

### 1. Backend (Railway / Render / Fly.io)

#### Шаг 1: Подготовка переменных окружения

Создайте файл `.env` или настройте переменные на хостинге:

```bash
# Обязательные переменные
DATABASE_URL=postgresql+asyncpg://user:password@host:5432/dbname
REDIS_URL=redis://host:6379/0
SECRET_KEY=<сгенерируйте_ключ_32_символа>
ADMIN_PASSWORD=<надежный_пароль>
ENVIRONMENT=production

# CORS - укажите ваши домены
CORS_ORIGINS=["https://your-miniapp-domain.com","https://your-admin-domain.com"]
```

**Генерация SECRET_KEY:**
```bash
python -c "import secrets; print(secrets.token_urlsafe(32))"
```

#### Шаг 2: Деплой на Railway

1. Создайте проект на [Railway](https://railway.app/)
2. Подключите GitHub репозиторий
3. Добавьте PostgreSQL базу данных
4. Добавьте Redis (или используйте Upstash)
5. Настройте переменные окружения
6. Railway автоматически применит миграции при первом деплое

**Или через CLI:**
```bash
railway login
railway init
railway add postgresql
railway add redis
railway variables set SECRET_KEY=<ваш_ключ>
railway variables set ADMIN_PASSWORD=<ваш_пароль>
railway variables set ENVIRONMENT=production
railway up
```

#### Шаг 3: Применение миграций

Если миграции не применились автоматически:

```bash
railway run alembic upgrade head
```

### 2. Frontend - Мини-приложение

#### Шаг 1: Сборка

```bash
cd frontend
flutter pub get
flutter build web --release \
  --target lib/mini_app/main.dart \
  --dart-define=API_BASE_URL=https://your-backend-url.com \
  --dart-define=ENVIRONMENT=production
```

#### Шаг 2: Деплой на Vercel

```bash
cd build/web
npx vercel --prod
```

**Или через GitHub:**
1. Подключите репозиторий к Vercel
2. Укажите:
   - Build Command: `flutter build web --release --target lib/mini_app/main.dart --dart-define=API_BASE_URL=https://your-backend-url.com --dart-define=ENVIRONMENT=production`
   - Output Directory: `build/web`
   - Install Command: `flutter pub get`

### 3. Frontend - Админ-панель

#### Шаг 1: Сборка

```bash
cd frontend
flutter build web --release \
  --target lib/admin_panel/main.dart \
  --dart-define=API_BASE_URL=https://your-backend-url.com \
  --dart-define=ENVIRONMENT=production
```

#### Шаг 2: Деплой

```bash
cd build/web
npx vercel --prod
```

### 4. Настройка Telegram Mini App

1. Создайте бота через [@BotFather](https://t.me/BotFather)
2. Отправьте `/newbot` и следуйте инструкциям
3. Отправьте `/newapp` и выберите вашего бота
4. Укажите:
   - Title: Название вашего магазина
   - Short name: короткое имя (будет в URL)
   - Description: описание
   - Photo: логотип (опционально)
   - **Web App URL**: URL вашего мини-приложения (например, `https://your-miniapp.vercel.app`)

### 5. Проверка

1. **Backend:**
   - `https://your-backend-url.com/health` → `{"status": "ok"}`
   - `https://your-backend-url.com/docs` → Swagger документация

2. **Frontend:**
   - Мини-приложение открывается в Telegram
   - Админ-панель открывается в браузере

3. **Тестирование:**
   - Просмотр каталога
   - Добавление в корзину
   - Создание заказа
   - Просмотр заказов в админ-панели

## ⚠️ Важные замечания

1. **CORS:** Убедитесь, что в `CORS_ORIGINS` указаны правильные домены frontend
2. **SECRET_KEY:** Обязательно измените с дефолтного значения
3. **ADMIN_PASSWORD:** Установите надежный пароль
4. **База данных:** Примените все миграции перед первым запуском
5. **Redis:** Для демо можно использовать бесплатный Upstash

## 🔧 Troubleshooting

### Backend не запускается
- Проверьте переменные окружения
- Проверьте подключение к БД: `railway run python -c "from app.database import engine; print(engine)"`
- Проверьте логи: `railway logs`

### Frontend не подключается к backend
- Проверьте CORS настройки
- Проверьте `API_BASE_URL` в build команде
- Проверьте, что backend доступен: `curl https://your-backend-url.com/health`

### Ошибки миграций
- Проверьте подключение к БД
- Примените миграции вручную: `railway run alembic upgrade head`

## 📚 Полезные команды

```bash
# Проверка подключения к БД
railway run python -c "from app.database import AsyncSessionLocal; import asyncio; asyncio.run(AsyncSessionLocal().__aenter__())"

# Просмотр логов
railway logs

# Применение миграций
railway run alembic upgrade head

# Создание новой миграции
railway run alembic revision --autogenerate -m "description"
```

