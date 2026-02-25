# Пошаговая инструкция по деплою

## 📋 Шаг 1: Подготовка Backend

### 1.1. Генерация секретных ключей

```bash
# Генерация SECRET_KEY
python3 -c "import secrets; print(secrets.token_urlsafe(32))"
```

Скопируйте полученный ключ - он понадобится на шаге 1.3.

### 1.2. Подготовка базы данных

**Вариант А: Railway (рекомендуется)**
1. Зайдите на https://railway.app/
2. Создайте аккаунт через GitHub
3. Создайте новый проект
4. Нажмите "New" → "Database" → "PostgreSQL"
5. Railway автоматически создаст базу данных

**Вариант Б: Supabase (бесплатно)**
1. Зайдите на https://supabase.com/
2. Создайте проект
3. В настройках проекта найдите "Connection string"
4. Скопируйте строку подключения

### 1.3. Подготовка Redis

**Вариант А: Upstash (бесплатно, рекомендуется)**
1. Зайдите на https://upstash.com/
2. Создайте аккаунт
3. Создайте Redis базу данных
4. Скопируйте "REST URL" (формат: `redis://default:password@host:6379`)

**Вариант Б: Railway**
1. В вашем Railway проекте нажмите "New" → "Database" → "Redis"

### 1.4. Деплой Backend на Railway

1. В Railway проекте нажмите "New" → "GitHub Repo"
2. Выберите ваш репозиторий
3. Выберите папку `backend` как root directory
4. Railway автоматически обнаружит Dockerfile и начнет деплой

### 1.5. Настройка переменных окружения в Railway

В настройках вашего сервиса (Settings → Variables) добавьте:

```bash
# Обязательные переменные
DATABASE_URL=postgresql+asyncpg://user:password@host:5432/dbname
REDIS_URL=redis://default:password@host:6379
SECRET_KEY=<вставьте_ключ_из_шага_1.1>
ADMIN_PASSWORD=<придумайте_надежный_пароль>
ENVIRONMENT=production

# CORS - замените на ваши реальные домены
CORS_ORIGINS=["https://your-miniapp.vercel.app","https://your-admin.vercel.app"]
```

**Как получить DATABASE_URL:**
- Railway: В настройках PostgreSQL базы → "Connect" → скопируйте "Postgres Connection URL"
- Supabase: В настройках проекта → "Database" → "Connection string" → выберите "URI"

**Как получить REDIS_URL:**
- Upstash: В настройках Redis → "REST URL"
- Railway: В настройках Redis → "Connect" → скопируйте URL

### 1.6. Применение миграций базы данных

После деплоя backend, примените миграции:

```bash
# Через Railway CLI
railway login
railway link  # выберите ваш проект
railway run alembic upgrade head
```

Или через Railway Dashboard:
1. Откройте ваш сервис backend
2. Перейдите в "Deployments"
3. Нажмите на последний деплой → "View Logs"
4. В консоли выполните: `railway run alembic upgrade head`

### 1.7. Проверка Backend

Откройте в браузере:
- `https://your-backend-url.railway.app/health` → должно быть `{"status": "ok"}`
- `https://your-backend-url.railway.app/docs` → должна открыться Swagger документация

**Скопируйте URL вашего backend** - он понадобится для frontend.

---

## 📱 Шаг 2: Деплой Frontend (Мини-приложение)

### 2.1. Подготовка к сборке

```bash
cd frontend
flutter pub get
```

### 2.2. Сборка для production

```bash
flutter build web --release \
  --target lib/mini_app/main.dart \
  --dart-define=API_BASE_URL=https://your-backend-url.railway.app \
  --dart-define=ENVIRONMENT=production
```

**Замените `your-backend-url.railway.app` на реальный URL вашего backend.**

### 2.3. Деплой на Vercel

**Вариант А: Через Vercel CLI**

```bash
# Установите Vercel CLI (если еще не установлен)
npm i -g vercel

# Войдите в аккаунт
vercel login

# Деплой
cd build/web
vercel --prod
```

**Вариант Б: Через GitHub + Vercel Dashboard**

1. Зайдите на https://vercel.com/
2. Создайте аккаунт через GitHub
3. Нажмите "Add New Project"
4. Импортируйте ваш репозиторий
5. Настройки проекта:
   - **Framework Preset:** Other
   - **Root Directory:** `frontend`
   - **Build Command:** 
     ```bash
     flutter pub get && flutter build web --release --target lib/mini_app/main.dart --dart-define=API_BASE_URL=https://your-backend-url.railway.app --dart-define=ENVIRONMENT=production
     ```
   - **Output Directory:** `build/web`
   - **Install Command:** `flutter pub get`
6. Добавьте Environment Variables:
   - `API_BASE_URL` = `https://your-backend-url.railway.app`
   - `ENVIRONMENT` = `production`
7. Нажмите "Deploy"

### 2.4. Проверка Frontend

Откройте URL, который дал Vercel (например, `https://your-miniapp.vercel.app`)

**Скопируйте URL вашего мини-приложения** - он понадобится для Telegram и CORS.

---

## 🖥️ Шаг 3: Деплой Админ-панели

### 3.1. Сборка для production

```bash
cd frontend
flutter build web --release \
  --target lib/admin_panel/main.dart \
  --dart-define=API_BASE_URL=https://your-backend-url.railway.app \
  --dart-define=ENVIRONMENT=production
```

### 3.2. Деплой на Vercel

**Вариант А: Через Vercel CLI**

```bash
cd build/web
vercel --prod
```

**Вариант Б: Через Vercel Dashboard**

1. В Vercel создайте новый проект
2. Импортируйте тот же репозиторий
3. Настройки проекта:
   - **Framework Preset:** Other
   - **Root Directory:** `frontend`
   - **Build Command:**
     ```bash
     flutter pub get && flutter build web --release --target lib/admin_panel/main.dart --dart-define=API_BASE_URL=https://your-backend-url.railway.app --dart-define=ENVIRONMENT=production
     ```
   - **Output Directory:** `build/web`
   - **Install Command:** `flutter pub get`
4. Добавьте те же Environment Variables
5. Нажмите "Deploy"

### 3.3. Проверка Админ-панели

Откройте URL админ-панели (например, `https://your-admin.vercel.app`)

**Скопируйте URL вашей админ-панели** - он понадобится для CORS.

---

## 🔒 Шаг 4: Настройка безопасности

### 4.1. Обновление CORS в Backend

Вернитесь в Railway → ваш backend сервис → Settings → Variables

Обновите `CORS_ORIGINS`:

```bash
CORS_ORIGINS=["https://your-miniapp.vercel.app","https://your-admin.vercel.app"]
```

**Важно:** Замените на реальные URL ваших приложений!

После обновления Railway автоматически перезапустит сервис.

### 4.2. Проверка безопасности

1. Откройте админ-панель
2. Попробуйте залогиниться с паролем, который указали в `ADMIN_PASSWORD`
3. Проверьте, что все работает

---

## 🤖 Шаг 5: Настройка Telegram Mini App

### 5.1. Создание бота

1. Откройте Telegram и найдите [@BotFather](https://t.me/BotFather)
2. Отправьте `/newbot`
3. Следуйте инструкциям:
   - Придумайте имя бота (например, "Мой Магазин")
   - Придумайте username (например, "my_shop_bot")
4. Сохраните токен бота (понадобится позже)

### 5.2. Создание Mini App

1. В том же чате с @BotFather отправьте `/newapp`
2. Выберите вашего бота из списка
3. Заполните данные:
   - **Title:** Название вашего магазина
   - **Short name:** Короткое имя (будет в URL, например: `myshop`)
   - **Description:** Описание магазина
   - **Photo:** Загрузите логотип (опционально)
   - **Web App URL:** `https://your-miniapp.vercel.app` (URL вашего мини-приложения)
4. Готово! Mini App создан

### 5.3. Тестирование Mini App

1. Найдите вашего бота в Telegram
2. Откройте бота
3. Нажмите на кнопку "Open" или отправьте `/start`
4. Mini App должен открыться

---

## ✅ Шаг 6: Финальная проверка

### 6.1. Проверка Backend

- [ ] `https://your-backend-url.railway.app/health` → `{"status": "ok"}`
- [ ] `https://your-backend-url.railway.app/docs` → открывается Swagger
- [ ] В Railway логах нет критичных ошибок

### 6.2. Проверка Frontend (Мини-приложение)

- [ ] Открывается в браузере
- [ ] Каталог товаров загружается
- [ ] Можно добавить товар в корзину
- [ ] Можно создать заказ

### 6.3. Проверка Админ-панели

- [ ] Открывается в браузере
- [ ] Можно залогиниться
- [ ] Видны заказы
- [ ] Можно управлять товарами

### 6.4. Проверка Telegram Mini App

- [ ] Открывается в Telegram
- [ ] Каталог загружается
- [ ] Можно создать заказ

---

## 🔧 Troubleshooting

### Backend не запускается

1. Проверьте логи в Railway
2. Проверьте, что все переменные окружения установлены
3. Проверьте формат `DATABASE_URL` и `REDIS_URL`

### Frontend не подключается к Backend

1. Проверьте `CORS_ORIGINS` в Railway
2. Проверьте, что URL в `API_BASE_URL` правильный
3. Откройте консоль браузера (F12) и проверьте ошибки

### Ошибки миграций

```bash
railway run alembic upgrade head
```

### База данных не подключается

1. Проверьте `DATABASE_URL` в Railway
2. Убедитесь, что база данных запущена
3. Проверьте, что формат URL правильный: `postgresql+asyncpg://...`

---

## 📝 Чеклист деплоя

- [ ] Backend развернут на Railway
- [ ] PostgreSQL база данных создана и подключена
- [ ] Redis настроен
- [ ] Все переменные окружения установлены
- [ ] Миграции применены
- [ ] Backend доступен по URL
- [ ] Frontend (мини-приложение) развернут на Vercel
- [ ] Админ-панель развернута на Vercel
- [ ] CORS настроен правильно
- [ ] Telegram Mini App создан и настроен
- [ ] Все функции работают

---

## 🎉 Готово!

Ваше приложение развернуто и готово к использованию!

**Важные URL для сохранения:**
- Backend: `https://your-backend-url.railway.app`
- Мини-приложение: `https://your-miniapp.vercel.app`
- Админ-панель: `https://your-admin.vercel.app`
- Telegram бот: `@your_bot_username`

