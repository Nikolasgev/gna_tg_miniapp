# Настройка ЮKassa

## Какой ключ нужен?

Для серверной части (backend) нужен **API ключ** (первый ключ, который вы предоставили):
```
test_2bOQknWTz14NTJcL1W8xpFFSlgPVAtNNZkb0jPVIHC4
```

**Ключ для мобильного SDK не нужен** - он используется только для нативных приложений iOS/Android, а у нас веб-интеграция через redirect.

## Что нужно сделать:

### 1. Получить Shop ID

Shop ID можно найти в личном кабинете ЮKassa:
1. Войдите в [личный кабинет ЮKassa](https://yookassa.ru/my)
2. Перейдите в раздел "Настройки" → "API"
3. Найдите **Shop ID** (обычно это числовой идентификатор, например: `123456`)

### 2. Настроить .env файл

Создайте файл `.env` в папке `backend/` на основе `.env.example`:

```bash
# YooKassa
YOOKASSA_SHOP_ID=1111342
YOOKASSA_SECRET_KEY=test_2bOQknWTz14NTJcL1W8xpFFSlgPVAtNNZkb0jPVIHC4
YOOKASSA_WEBHOOK_SECRET=  # Опционально, для проверки подписи webhook
```

**✅ Настроено!** Shop ID и Secret Key уже добавлены в `.env` файл.

### 3. Настроить Webhook (ОБЯЗАТЕЛЬНО для обновления статуса оплаты)

**⚠️ ВАЖНО:** Без webhook статус оплаты не будет обновляться автоматически!

#### Для локальной разработки (через ngrok):

1. Установите [ngrok](https://ngrok.com/)
2. Запустите ngrok: `ngrok http 8000`
3. Скопируйте HTTPS URL (например: `https://abc123.ngrok.io`)
4. В личном кабинете ЮKassa перейдите в "Настройки" → "Уведомления"
5. Добавьте URL для webhook: `https://abc123.ngrok.io/api/v1/payments/webhook/yookassa`
6. Скопируйте секретный ключ webhook и добавьте его в `.env` как `YOOKASSA_WEBHOOK_SECRET`

#### Для production:

1. В личном кабинете ЮKassa перейдите в "Настройки" → "Уведомления"
2. Добавьте URL для webhook: `https://ваш-домен.com/api/v1/payments/webhook/yookassa`
3. Скопируйте секретный ключ webhook и добавьте его в `.env` как `YOOKASSA_WEBHOOK_SECRET`

**Проверка webhook:**
- После настройки webhook, при оплате заказа YooKassa отправит POST запрос на ваш endpoint
- Проверьте логи backend: `docker-compose logs backend --tail 50 | grep -i webhook`
- Должны появиться логи с префиксом "=== YooKassa Webhook received ==="

### 4. Проверить работу

После настройки перезапустите backend и попробуйте создать заказ с онлайн-оплатой.

## Важно:

- **Тестовый режим**: Ключи, начинающиеся с `test_`, работают только в тестовом режиме
- **Продакшн**: Для реальных платежей нужны ключи, начинающиеся с `live_`
- **Shop ID**: Обязателен для работы API ЮKassa

## Формат авторизации

ЮKassa использует Basic Authentication с форматом:
```
Authorization: Basic base64(shop_id:secret_key)
```

Код автоматически формирует эту строку из настроек.

