# Настройка переменных окружения в Railway

Если GitHub подключён к **монорепо** (корень репозитория содержит `backend/` и `frontend/`), в настройках сервиса Railway задайте **Root Directory** = `backend`. Иначе образ соберётся не из той папки. Подробнее: [RAILWAY_MONOREPO.md](../RAILWAY_MONOREPO.md).

## Шаг 1: Откройте сервис backend в Railway Dashboard

1. Зайдите на https://railway.app/
2. Откройте проект `capable-tenderness` (или ваш проект)
3. Откройте сервис `gna_tg_miniapp` (backend)
4. Перейдите на вкладку **"Variables"**

## Шаг 2: Добавьте/обновите переменные окружения

### Обязательные переменные:

#### 1. DATABASE_URL
Скопируйте из Railway → Postgres → **Variables** / **Connect** (внутренний хост `postgres.railway.internal`):
```
postgresql://postgres:<ПАРОЛЬ_ИЗ_RAILWAY>@postgres.railway.internal:5432/railway
```
**Важно:** 
- Используйте внутренний URL (`postgres.railway.internal`), а не публичный
- Код автоматически конвертирует `postgresql://` в `postgresql+asyncpg://` при подключении
- Можно также указать напрямую: `postgresql+asyncpg://postgres:...@postgres.railway.internal:5432/railway`

#### 2. REDIS_URL
Скопируйте из Railway → Redis → **Variables** (внутренний хост `redis.railway.internal`):
```
redis://default:<ПАРОЛЬ>@redis.railway.internal:6379
```
**Важно:** Используйте внутренний URL (`redis.railway.internal`), а не публичный.

#### 3. SECRET_KEY
Сгенерируйте случайный секретный ключ (минимум 32 символа):
```bash
# В терминале:
python -c "import secrets; print(secrets.token_urlsafe(32))"
```
Или используйте онлайн генератор: https://randomkeygen.com/

Пример значения (учебный проект — см. `backend/.env.example`):
```
gna-tg-store-edu-secret-key-32chars-min-ok!
```

#### 4. ADMIN_PASSWORD
Пароль для входа в админ-панель. В `ENVIRONMENT=production` нельзя оставить значение по умолчанию `admin123` (см. `app/config.py`).

**Учебный проект:** можно задать тот же пароль, что в `backend/.env.example`:
```
gna-edu-demo-2026
```
Тогда в Variables также укажите `SECRET_KEY` из того же файла (не короче 32 символов).

#### 5. ENVIRONMENT
```
production
```

#### 6. CORS_ORIGINS
JSON массив разрешенных origins (для временного тестирования можно разрешить все):
```json
["*"]
```

Или конкретные домены (рекомендуется для production):
```json
["https://your-frontend-domain.com", "https://your-admin-domain.com"]
```

**Mini App на GitHub Pages** — браузер шлёт `Origin: https://nikolasgev.github.io` (без пути к репозиторию). Обязательно добавьте этот origin, иначе CORS заблокирует API:
```json
["https://nikolasgev.github.io"]
```
Или вместе с URL вашего API:
```json
["https://nikolasgev.github.io","https://gnatgminiapp-production.up.railway.app"]
```

Если переменная `CORS_ORIGINS` **не задана** в Railway, подставляются значения по умолчанию из `app/config.py` (там уже есть `https://nikolasgev.github.io`).

Проверка с локальной машины (из корня монорепо):
```bash
chmod +x scripts/check_production_readiness.sh
./scripts/check_production_readiness.sh
```

### Опциональные переменные:

- `TELEGRAM_BOT_TOKEN` — **обязателен для production Mini App**: валидация WebApp, уведомления пользователю о заказе. Токен из @BotFather.
- `DADATA_API_KEY` - API ключ для DaData (для автодополнения адресов)
- `YOOKASSA_SHOP_ID` - ID магазина ЮKassa
- `YOOKASSA_SECRET_KEY` - секретный ключ ЮKassa
- `YANDEX_DELIVERY_TOKEN` - токен Яндекс Доставки

## Шаг 3: Проверьте, что переменные сохранены

После добавления всех переменных:
1. Railway автоматически перезапустит сервис
2. Проверьте логи в разделе "Deployments" → "View Logs"
3. Убедитесь, что нет ошибок подключения к базе данных

## Шаг 4: Миграции базы данных

**Автоматически при каждом деплое:** в `railway.json` задан `preDeployCommand`:  
`python -m alembic upgrade head`. Команда выполняется **в сети Railway** (доступен `postgres.railway.internal`). В логах деплоя смотрите этап **Pre-deploy**.

**Почему не `railway run alembic` с Mac:** в `DATABASE_URL` часто указан хост `*.railway.internal` — с вашего компьютера DNS его не находит (`nodename nor servname not known`). Это нормально.

**Если нужно прогнать миграции вручную с ноутбука:** в Postgres в Railway возьмите **публичный** connection URL (Connect → Public networking), временно задайте его и выполните из `backend` с venv проекта:

```bash
source venv/bin/activate  # при необходимости создайте venv и pip install -r requirements.txt
DATABASE_URL='postgresql://...публичный хост...' python -m alembic upgrade head
```

Не коммитьте публичный URL в репозиторий.

## Проверка подключения

После настройки проверьте, что backend работает:
1. Откройте URL вашего сервиса: `https://gnatgminiapp-production.up.railway.app`
2. Проверьте `/docs` - должна открыться документация API
3. Проверьте `/api/v1/businesses/default-business` - должен вернуться JSON с настройками бизнеса

## Важные замечания

1. **Внутренние URL vs Публичные URL:**
   - Используйте `postgres.railway.internal` и `redis.railway.internal` для подключения внутри Railway
   - Публичные URL (`*.proxy.rlwy.net`) используются только для внешних подключений

2. **Безопасность:**
   - Никогда не коммитьте `SECRET_KEY` и `ADMIN_PASSWORD` в Git
   - Используйте сильные пароли для production
   - Ограничьте `CORS_ORIGINS` конкретными доменами в production

3. **Автоматическая конвертация URL:**
   - Код автоматически конвертирует `postgresql://` в `postgresql+asyncpg://`
   - Вам не нужно вручную менять формат URL

## Товары и каталог в production (пустой каталог / «Ошибка загрузки»)

1. **Postgres и Redis** на canvas Railway должны быть **Online** — иначе API зависнет или вернёт ошибку.
2. **Миграции** выполняются при деплое (`preDeployCommand` в `railway.json`).
3. **Сиды** (бизнес `default-business` + демо-категории и товары) в облаке не запускаются автоматически.

С Mac **не** используйте `postgres.railway.internal` (DNS не резолвится). Возьмите **публичный** URL Postgres: Railway → сервис Postgres → **Connect** / **Variables** (host вида `*.proxy.rlwy.net`).

```bash
cd backend
source venv/bin/activate   # при необходимости: pip install -r requirements.txt
# Подставьте реальный URL из Railway → Postgres → Connect (Public Network), целиком — не буквально USER/PASS/HOST/PORT
export DATABASE_URL='postgresql://postgres:ВАШ_ПАРОЛЬ@xxxx.proxy.rlwy.net:5432/railway'
./scripts/seed_production_data.sh
```

Либо по шагам: `python create_production_business.py`, затем `python create_demo_menu.py`.

После сидов перезапустите сервис приложения в Railway (или подождите), чтобы сбросить кэш Redis. Убедитесь, что `CORS_ORIGINS` включает URL фронта (Vercel / GitHub Pages).

