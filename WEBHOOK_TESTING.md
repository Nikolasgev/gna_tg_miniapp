# Тестирование YooKassa Webhook

## Проблема: Статус оплаты не обновляется

Если вы оплатили заказ, но статус не изменился, проверьте следующее:

### 1. Проверьте, что webhook настроен в YooKassa

1. Войдите в [личный кабинет YooKassa](https://yookassa.ru/my)
2. Перейдите в "Настройки" → "Уведомления"
3. Убедитесь, что указан URL webhook: `https://ваш-домен.com/api/v1/payments/webhook/yookassa`

### 2. Для локальной разработки используйте ngrok

Если вы тестируете локально, YooKassa не сможет отправить webhook на `localhost`. Используйте ngrok:

```bash
# Установите ngrok (если еще не установлен)
# macOS: brew install ngrok
# Linux: скачайте с https://ngrok.com/

# Запустите ngrok
ngrok http 8000

# Скопируйте HTTPS URL (например: https://abc123.ngrok.io)
# Добавьте его в YooKassa как webhook URL:
# https://abc123.ngrok.io/api/v1/payments/webhook/yookassa
```

### 3. Проверьте логи backend

После оплаты проверьте логи:

```bash
cd backend
docker-compose logs backend --tail 100 | grep -i "webhook\|payment\|yookassa"
```

Должны появиться логи:
- `=== YooKassa Webhook received ===`
- `=== Processing YooKassa webhook ===`
- `✅ Payment processed successfully`

### 4. Проверьте, что платеж создан в БД

```bash
docker exec tg_store_postgres psql -U postgres -d tg_store_db -c "SELECT id, provider_payment_id, status, order_id FROM payments ORDER BY created_at DESC LIMIT 5;"
```

### 5. Проверьте статус заказа

```bash
docker exec tg_store_postgres psql -U postgres -d tg_store_db -c "SELECT id, payment_status, status FROM orders ORDER BY created_at DESC LIMIT 5;"
```

### 6. Ручное тестирование webhook (для отладки)

Вы можете вручную отправить тестовый webhook:

```bash
# Получите provider_payment_id из БД
PROVIDER_PAYMENT_ID=$(docker exec tg_store_postgres psql -U postgres -d tg_store_db -t -c "SELECT provider_payment_id FROM payments ORDER BY created_at DESC LIMIT 1;")

# Отправьте тестовый webhook
curl -X POST http://localhost:8000/api/v1/payments/webhook/yookassa \
  -H "Content-Type: application/json" \
  -d "{
    \"event\": \"payment.succeeded\",
    \"object\": {
      \"id\": \"$PROVIDER_PAYMENT_ID\",
      \"status\": \"succeeded\",
      \"amount\": {
        \"value\": \"100.00\",
        \"currency\": \"RUB\"
      }
    }
  }"
```

### 7. Проверьте формат данных от YooKassa

YooKassa отправляет webhook в формате:
```json
{
  "type": "notification",
  "event": "payment.succeeded",
  "object": {
    "id": "payment_id",
    "status": "succeeded",
    ...
  }
}
```

Убедитесь, что ваш endpoint правильно обрабатывает этот формат.

### 8. Проверка подписи webhook (опционально)

Если вы настроили `YOOKASSA_WEBHOOK_SECRET`, убедитесь, что:
1. Секретный ключ совпадает с тем, что указан в YooKassa
2. Подпись правильно вычисляется

## Решение проблем

### Webhook не приходит

1. Проверьте, что URL доступен из интернета (используйте ngrok для локальной разработки)
2. Проверьте, что URL указан правильно в YooKassa
3. Проверьте логи YooKassa в личном кабинете

### Webhook приходит, но статус не обновляется

1. Проверьте логи backend - должны быть сообщения об обработке webhook
2. Проверьте, что `provider_payment_id` в webhook совпадает с `provider_payment_id` в БД
3. Проверьте, что событие имеет тип `payment.succeeded`

### Ошибка "Invalid signature"

1. Убедитесь, что `YOOKASSA_WEBHOOK_SECRET` совпадает с секретным ключом в YooKassa
2. Или временно отключите проверку подписи (удалите `YOOKASSA_WEBHOOK_SECRET` из `.env`)

