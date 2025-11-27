# 🧪 Руководство по тестированию YooKassa Webhook

## Вариант 1: Быстрое тестирование (локально, без ngrok)

### Шаг 1: Создайте заказ с онлайн-оплатой

1. Откройте приложение в браузере
2. Добавьте товары в корзину
3. Оформите заказ с **онлайн-оплатой**
4. Скопируйте ссылку на оплату (она откроется в новой вкладке)
5. **НЕ оплачивайте** пока - сначала настройте тестирование

### Шаг 2: Получите provider_payment_id

```bash
cd backend
docker exec tg_store_postgres psql -U postgres -d tg_store_db -c "SELECT provider_payment_id, status, order_id FROM payments ORDER BY created_at DESC LIMIT 1;"
```

Скопируйте `provider_payment_id` (например: `30b7f59b-000f-5000-8000-1aef152bc09c`)

### Шаг 3: Отправьте тестовый webhook вручную

Используйте готовый скрипт:

```bash
cd backend
./test_webhook.sh
```

Или вручную:

```bash
# Замените PROVIDER_PAYMENT_ID на реальный ID из шага 2
PROVIDER_PAYMENT_ID="30b7f59b-000f-5000-8000-1aef152bc09c"

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

### Шаг 4: Проверьте результат

```bash
# Проверьте статус платежа и заказа
docker exec tg_store_postgres psql -U postgres -d tg_store_db -c "
SELECT 
    p.provider_payment_id,
    p.status as payment_status,
    o.payment_status as order_payment_status,
    o.status as order_status
FROM payments p
JOIN orders o ON p.order_id = o.id
ORDER BY p.created_at DESC LIMIT 1;
"
```

**Ожидаемый результат:**
- `payment_status` должен быть `succeeded`
- `order_payment_status` должен быть `paid`

### Шаг 5: Проверьте логи

```bash
docker-compose logs backend --tail 50 | grep -i "webhook\|payment"
```

Должны увидеть:
- `=== YooKassa Webhook received ===`
- `✅ Payment processed successfully`

---

## Вариант 2: Полное тестирование с реальным webhook от YooKassa

### Шаг 1: Установите и запустите ngrok

```bash
# Установите ngrok (если еще не установлен)
# macOS:
brew install ngrok

# Или скачайте с https://ngrok.com/

# Запустите ngrok
ngrok http 8000
```

Скопируйте HTTPS URL (например: `https://abc123.ngrok.io`)

### Шаг 2: Настройте webhook в YooKassa

1. Войдите в [личный кабинет YooKassa](https://yookassa.ru/my)
2. Перейдите в **"Настройки"** → **"Уведомления"**
3. Нажмите **"Добавить URL"**
4. Введите URL: `https://ваш-ngrok-url.ngrok.io/api/v1/payments/webhook/yookassa`
   - Например: `https://abc123.ngrok.io/api/v1/payments/webhook/yookassa`
5. Сохраните

### Шаг 3: Создайте заказ и оплатите

1. Откройте приложение в браузере
2. Добавьте товары в корзину
3. Оформите заказ с **онлайн-оплатой**
4. Оплатите заказ на странице YooKassa (используйте тестовые данные карты)

### Шаг 4: Проверьте логи

```bash
cd backend
docker-compose logs backend --tail 100 | grep -i "webhook\|payment\|yookassa"
```

Должны увидеть:
- `=== YooKassa Webhook received ===`
- `Event type: payment.succeeded`
- `✅ Payment processed successfully`

### Шаг 5: Проверьте статус в БД

```bash
docker exec tg_store_postgres psql -U postgres -d tg_store_db -c "
SELECT 
    p.provider_payment_id,
    p.status as payment_status,
    o.payment_status as order_payment_status,
    o.status as order_status,
    o.total_amount
FROM payments p
JOIN orders o ON p.order_id = o.id
ORDER BY p.created_at DESC LIMIT 1;
"
```

---

## 🔍 Отладка проблем

### Проблема: Webhook не приходит

**Решение:**
1. Убедитесь, что ngrok запущен и URL доступен
2. Проверьте, что URL правильно указан в YooKassa
3. Проверьте логи ngrok: откройте http://127.0.0.1:4040 в браузере

### Проблема: Webhook приходит, но статус не обновляется

**Решение:**
1. Проверьте логи backend - должны быть сообщения об обработке
2. Убедитесь, что `provider_payment_id` в webhook совпадает с БД
3. Проверьте формат данных webhook

### Проблема: Ошибка "Invalid signature"

**Решение:**
1. Если используете `YOOKASSA_WEBHOOK_SECRET`, убедитесь, что он совпадает с ключом в YooKassa
2. Или временно отключите проверку подписи (удалите `YOOKASSA_WEBHOOK_SECRET` из `.env`)

---

## 📝 Тестовые данные карты для YooKassa

Для тестирования используйте:
- **Номер карты:** `5555 5555 5555 4444`
- **Срок действия:** любая будущая дата (например: `12/25`)
- **CVC:** любые 3 цифры (например: `123`)
- **Имя держателя:** любое имя

---

## 🚀 Быстрый старт (самый простой способ)

```bash
# 1. Создайте заказ с онлайн-оплатой в приложении

# 2. Запустите скрипт тестирования
cd backend
./test_webhook.sh

# 3. Проверьте результат в БД
docker exec tg_store_postgres psql -U postgres -d tg_store_db -c "
SELECT p.status, o.payment_status 
FROM payments p 
JOIN orders o ON p.order_id = o.id 
ORDER BY p.created_at DESC LIMIT 1;
"
```

Если статус изменился на `succeeded` и `paid` - всё работает! ✅

