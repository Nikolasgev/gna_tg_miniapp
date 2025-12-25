# Настройка переменных окружения в Railway

## Шаг 1: Откройте сервис backend в Railway Dashboard

1. Зайдите на https://railway.app/
2. Откройте проект `capable-tenderness` (или ваш проект)
3. Откройте сервис `gna_tg_miniapp` (backend)
4. Перейдите на вкладку **"Variables"**

## Шаг 2: Добавьте/обновите переменные окружения

### Обязательные переменные:

#### 1. DATABASE_URL
```
postgresql://postgres:rCAMSghIZMgqeMQxCStweiMPzIxoXrbL@postgres.railway.internal:5432/railway
```
**Важно:** 
- Используйте внутренний URL (`postgres.railway.internal`), а не публичный
- Код автоматически конвертирует `postgresql://` в `postgresql+asyncpg://` при подключении
- Можно также указать напрямую: `postgresql+asyncpg://postgres:...@postgres.railway.internal:5432/railway`

#### 2. REDIS_URL
```
redis://default:CjVewmwhZmEfPLbQhYftbucwwqFmAusW@redis.railway.internal:6379
```
**Важно:** Используйте внутренний URL (`redis.railway.internal`), а не публичный.

#### 3. SECRET_KEY
Сгенерируйте случайный секретный ключ (минимум 32 символа):
```bash
# В терминале:
python -c "import secrets; print(secrets.token_urlsafe(32))"
```
Или используйте онлайн генератор: https://randomkeygen.com/

Пример значения:
```
your-super-secret-key-min-32-chars-change-this
```

#### 4. ADMIN_PASSWORD
Пароль для входа в админ-панель (минимум 8 символов, буквы и цифры):
```
your-admin-password-123
```

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

### Опциональные переменные:

- `TELEGRAM_BOT_TOKEN` - токен Telegram бота (если используется)
- `DADATA_API_KEY` - API ключ для DaData (для автодополнения адресов)
- `YOOKASSA_SHOP_ID` - ID магазина ЮKassa
- `YOOKASSA_SECRET_KEY` - секретный ключ ЮKassa
- `YANDEX_DELIVERY_TOKEN` - токен Яндекс Доставки

## Шаг 3: Проверьте, что переменные сохранены

После добавления всех переменных:
1. Railway автоматически перезапустит сервис
2. Проверьте логи в разделе "Deployments" → "View Logs"
3. Убедитесь, что нет ошибок подключения к базе данных

## Шаг 4: Примените миграции базы данных

После настройки переменных нужно применить миграции:

```bash
# Через Railway CLI (из директории backend):
cd backend
railway link  # если еще не привязан
railway run ./venv/bin/alembic upgrade head
```

Или через Railway Dashboard:
1. Откройте сервис `gna_tg_miniapp`
2. Перейдите в "Deployments" → "View Logs"
3. Выполните команду через терминал (если доступен)

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

