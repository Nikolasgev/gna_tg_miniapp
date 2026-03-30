#!/bin/bash

# Скрипт для тестирования YooKassa webhook

echo "🔍 Тестирование YooKassa Webhook"
echo ""

# Получаем последний provider_payment_id из БД
echo "📊 Получаем последний платеж из БД..."
PROVIDER_PAYMENT_ID=$(docker exec tg_store_postgres psql -U postgres -d tg_store_db -t -A -c "SELECT provider_payment_id FROM payments ORDER BY created_at DESC LIMIT 1;")

if [ -z "$PROVIDER_PAYMENT_ID" ]; then
    echo "❌ Не найдено платежей в БД. Сначала создайте заказ с онлайн-оплатой."
    exit 1
fi

echo "✅ Найден платеж: $PROVIDER_PAYMENT_ID"
echo ""

# Получаем информацию о платеже
echo "📋 Информация о платеже:"
docker exec tg_store_postgres psql -U postgres -d tg_store_db -c "
SELECT 
    p.id as payment_id,
    p.provider_payment_id,
    p.status as payment_status,
    o.id as order_id,
    o.payment_status as order_payment_status,
    o.status as order_status,
    o.total_amount
FROM payments p
JOIN orders o ON p.order_id = o.id
WHERE p.provider_payment_id = '$PROVIDER_PAYMENT_ID';
"

echo ""
echo "🚀 Отправляем тестовый webhook..."
echo ""

# Отправляем тестовый webhook
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
      },
      \"metadata\": {
        \"order_id\": \"test\"
      }
    }
  }" \
  -w "\n\nHTTP Status: %{http_code}\n"

echo ""
echo "✅ Webhook отправлен!"
echo ""
echo "📊 Проверяем обновленный статус..."
sleep 1

docker exec tg_store_postgres psql -U postgres -d tg_store_db -c "
SELECT 
    p.id as payment_id,
    p.provider_payment_id,
    p.status as payment_status,
    o.id as order_id,
    o.payment_status as order_payment_status,
    o.status as order_status
FROM payments p
JOIN orders o ON p.order_id = o.id
WHERE p.provider_payment_id = '$PROVIDER_PAYMENT_ID';
"

echo ""
echo "📝 Проверьте логи backend:"
echo "   docker-compose logs backend --tail 50 | grep -i webhook"

