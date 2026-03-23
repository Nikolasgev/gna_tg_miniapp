# Подключение Mini App к Telegram боту

## Что нужно для подключения

### 1. **Домен с HTTPS (обязательно!)**
   - Telegram требует **HTTPS** для Mini App
   - Можно использовать:
     - **Vercel** (бесплатно, автоматический HTTPS)
     - **Netlify** (бесплатно, автоматический HTTPS)
     - **GitHub Pages** (бесплатно, но нужен свой домен для HTTPS)
     - **Railway** (платно, но можно использовать для frontend)
     - **Любой другой хостинг с HTTPS**

### 2. **Telegram бот**
   - Создается через [@BotFather](https://t.me/BotFather)
   - Нужен токен бота для валидации данных

### 3. **Backend с HTTPS**
   - Backend тоже должен быть доступен по HTTPS
   - Можно использовать Railway, Render, или любой другой хостинг

---

## Пошаговая инструкция

### Шаг 1: Создание Telegram бота

1. Откройте Telegram и найдите [@BotFather](https://t.me/BotFather)
2. Отправьте команду `/newbot`
3. Следуйте инструкциям:
   - **Имя бота:** например, "Мой Магазин"
   - **Username:** например, `my_shop_bot` (должен заканчиваться на `bot`)
4. **Сохраните токен бота** (выглядит как `123456789:ABCdefGHIjklMNOpqrsTUVwxyz`)

### Шаг 2: Создание Mini App в BotFather

1. В том же чате с @BotFather отправьте `/newapp`
2. Выберите вашего бота из списка
3. Заполните данные:
   - **Title:** Название вашего магазина (например, "Мой магазин")
   - **Short name:** Короткое имя (будет в URL, например: `myshop`)
   - **Description:** Описание магазина
   - **Photo:** Загрузите логотип (опционально)
   - **Web App URL:** `https://your-miniapp.vercel.app` (URL вашего мини-приложения)
   - **GIF:** (опционально) Анимированная превью
   - **Short name:** (опционально) Короткое имя для кнопки

4. Готово! Mini App создан

### Шаг 3: Деплой Frontend (Mini App)

#### Вариант A: Vercel (рекомендуется)

1. **Установите Vercel CLI:**
   ```bash
   npm i -g vercel
   ```

2. **Соберите приложение:**
   ```bash
   cd frontend
   flutter pub get
   flutter build web --release \
     --target lib/mini_app/main.dart \
     --dart-define=API_BASE_URL=https://your-backend-url.com \
     --dart-define=ENVIRONMENT=production
   ```

3. **Деплой:**
   ```bash
   cd build/web
   vercel --prod
   ```

4. **Получите URL:** Vercel даст вам URL вида `https://your-app.vercel.app`

#### Вариант B: Netlify

1. **Соберите приложение** (как в варианте A)
2. **Деплой:**
   ```bash
   cd build/web
   netlify deploy --prod
   ```

#### Вариант C: GitHub Pages

1. Соберите приложение
2. Загрузите содержимое `build/web` в репозиторий
3. Настройте GitHub Pages в настройках репозитория

### Шаг 4: Настройка Backend

1. **Добавьте токен бота в переменные окружения:**
   ```bash
   # В Railway, Render или другом хостинге
   TELEGRAM_BOT_TOKEN=123456789:ABCdefGHIjklMNOpqrsTUVwxyz
   ```

   С этим токеном backend:
   - при вызове `POST /api/v1/telegram/validate_init_data` сохраняет покупателя в таблице `users` (поле `telegram_id`, роль `client`, логин вида `tg_<id>`);
   - после создания заказа с непустым `user_telegram_id` отправляет пользователю в Telegram сообщение с кратким составом заказа (Bot API `sendMessage`).

   **Важно:** чтобы бот мог написать пользователю в личку, пользователь хотя бы раз должен нажать **«Запустить»** / отправить **`/start`** этому боту в Telegram. Иначе Telegram вернёт ошибку «bot was blocked by the user» / «chat not found».

### Запуск бота-обработчика (polling)

Помимо вызовов Bot API из backend (валидация WebApp, уведомления о заказах) можно запустить **отдельный процесс**, который слушает обновления через long polling: команды `/start`, `/help` и текстовые сообщения (каркас поддержки).

Рядом с API (второй процесс на том же хосте или отдельный worker):

```bash
cd backend
export TELEGRAM_BOT_TOKEN=<ваш_токен>
python run_telegram_bot.py
```

Используется библиотека `python-telegram-bot` (polling; для webhook при стабильном HTTPS можно позже добавить endpoint в FastAPI и `setWebhook`).

2. **Обновите CORS настройки** (если нужно):
   - Добавьте домен вашего Mini App в `CORS_ORIGINS`
   - Или оставьте `*` для development

### Шаг 5: Обновление Web App URL в BotFather

1. Откройте @BotFather
2. Отправьте `/myapps`
3. Выберите вашего бота
4. Выберите "Edit Web App"
5. Обновите **Web App URL** на ваш новый URL

---

## Проверка работы

### 1. Тест в Telegram

1. Найдите вашего бота в Telegram
2. Откройте бота
3. Нажмите на кнопку "Open" или отправьте `/start`
4. Mini App должен открыться

### 2. Проверка в браузере

Откройте URL вашего Mini App в браузере:
- Должен открываться без ошибок
- Каталог должен загружаться
- Не должно быть ошибок CORS

### 3. Проверка Backend

```bash
# Проверка health
curl https://your-backend-url.com/api/v1/health

# Проверка продуктов
curl https://your-backend-url.com/api/v1/products/default-business/products
```

---

## Важные моменты

### ✅ Обязательные требования:

1. **HTTPS обязателен** - Telegram не работает с HTTP
2. **Домен должен быть доступен публично** - не localhost
3. **Backend должен быть на HTTPS** - для безопасности
4. **CORS должен разрешать ваш домен** - или использовать `*` в development

### ⚠️ Частые проблемы:

1. **"Mini App не открывается"**
   - Проверьте, что URL начинается с `https://`
   - Проверьте, что сайт доступен из интернета
   - Проверьте консоль браузера на ошибки

2. **"CORS ошибка"**
   - Добавьте домен Mini App в `CORS_ORIGINS` на backend
   - Или используйте `*` для development

3. **"Не загружаются продукты"**
   - Проверьте, что `API_BASE_URL` указан правильно
   - Проверьте, что backend доступен по HTTPS
   - Проверьте логи backend

4. **"Ошибка валидации init_data"**
   - Проверьте, что `TELEGRAM_BOT_TOKEN` установлен правильно
   - Проверьте, что токен соответствует боту, для которого создан Mini App

---

## Быстрый старт (для тестирования)

Если нужно быстро протестировать локально:

1. **Используйте ngrok для туннеля:**
   ```bash
   # Установите ngrok
   brew install ngrok  # macOS
   # или скачайте с https://ngrok.com/

   # Запустите туннель для frontend
   ngrok http 8080

   # Запустите туннель для backend
   ngrok http 8000
   ```

2. **Используйте полученные HTTPS URL:**
   - Frontend: `https://xxxx.ngrok.io`
   - Backend: `https://yyyy.ngrok.io`

3. **Настройте в BotFather:**
   - Web App URL: `https://xxxx.ngrok.io`

4. **Обновите API_BASE_URL:**
   ```bash
   flutter build web --release \
     --target lib/mini_app/main.dart \
     --dart-define=API_BASE_URL=https://yyyy.ngrok.io \
     --dart-define=ENVIRONMENT=production
   ```

---

## Структура URL

После настройки у вас будет:

- **Mini App URL:** `https://your-miniapp.vercel.app`
- **Backend URL:** `https://your-backend.railway.app`
- **Admin Panel URL:** `https://your-admin.vercel.app` (опционально)

Все должны быть доступны по HTTPS!

---

## Дополнительные настройки

### Настройка кнопки в боте

После создания Mini App, бот автоматически получит кнопку "Open" в интерфейсе.

Вы также можете добавить кнопку вручную через BotFather:
1. Отправьте `/mybots`
2. Выберите вашего бота
3. Выберите "Bot Settings" → "Menu Button"
4. Настройте кнопку

### Уведомления от бота (опционально)

Если нужно отправлять уведомления пользователям:

1. Убедитесь, что `TELEGRAM_BOT_TOKEN` установлен
2. Используйте Telegram Bot API для отправки сообщений
3. Пример кода есть в `backend/app/core/telegram.py`

---

## Готово! 🎉

После выполнения всех шагов ваше Mini App будет доступно в Telegram через вашего бота.

Для открытия:
1. Найдите бота в Telegram
2. Нажмите кнопку "Open" или отправьте `/start`
3. Mini App откроется внутри Telegram
