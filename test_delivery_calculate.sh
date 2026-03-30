#!/bin/bash

# Скрипт для тестирования расчета стоимости доставки

echo "🚚 Тестирование расчета стоимости доставки через Яндекс Доставку"
echo ""

# Проверяем, что backend запущен
if ! curl -s http://localhost:8000/docs > /dev/null 2>&1; then
    echo "❌ Backend не запущен. Запустите: docker-compose up -d"
    exit 1
fi

echo "📤 Отправляем запрос на расчет стоимости доставки..."
echo ""

curl -X POST http://localhost:8000/api/v1/delivery/calculate \
  -H "Content-Type: application/json" \
  -d '{
    "from_address": {
      "fullname": "Москва, Красная площадь, 1",
      "coordinates": [37.6173, 55.7558],
      "city": "Москва",
      "country": "Россия",
      "street": "Красная площадь"
    },
    "to_address": {
      "fullname": "Москва, Тверская улица, 10",
      "coordinates": [37.6064, 55.7558],
      "city": "Москва",
      "country": "Россия",
      "street": "Тверская улица"
    },
    "items": [
      {
        "quantity": 1,
        "weight": 0.5,
        "size": {
          "length": 0.1,
          "width": 0.1,
          "height": 0.1
        }
      }
    ],
    "taxi_classes": ["express"]
  }' \
  -w "\n\nHTTP Status: %{http_code}\n" | jq '.' 2>/dev/null || cat

echo ""
echo "✅ Тест завершен!"
echo ""
echo "💡 Если получили ошибку 'Yandex Delivery token not configured', добавьте токен в .env:"
echo "   YANDEX_DELIVERY_TOKEN=ваш_токен"

