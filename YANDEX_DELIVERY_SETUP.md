# Настройка Яндекс Доставки

## Получение API токена

1. Зарегистрируйтесь в [личном кабинете Яндекс Доставки](https://dostavka.yandex.ru/)
2. Перейдите в раздел "Интеграции" → "API"
3. Создайте API токен
4. Скопируйте токен

## Настройка .env

Добавьте в файл `.env` в папке `backend/`:

```bash
# Яндекс Доставка
YANDEX_DELIVERY_TOKEN=ваш_токен_здесь
```

## Тестирование расчета стоимости доставки

### Через API endpoint

```bash
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
  }'
```

### Через тестовый скрипт

```bash
cd backend
python test_yandex_delivery.py
```

## Получение координат адреса

Для расчета доставки нужны координаты адресов. Можно использовать:

1. **Яндекс Геокодер API** - для преобразования адреса в координаты
2. **Вручную** - найти координаты через Яндекс Карты

Пример использования Яндекс Геокодера:
```python
import httpx

async def geocode_address(address: str) -> tuple[float, float]:
    """Преобразует адрес в координаты через Яндекс Геокодер."""
    async with httpx.AsyncClient() as client:
        response = await client.get(
            "https://geocode-maps.yandex.ru/1.x/",
            params={
                "apikey": "ваш_геокодер_ключ",
                "geocode": address,
                "format": "json",
            }
        )
        # Парсим координаты из ответа
        # ...
```

## Формат данных

### Адрес (AddressRequest)
- `fullname` (обязательно) - полный адрес
- `coordinates` (обязательно) - [долгота, широта]
- `city` (обязательно) - город
- `country` (опционально, по умолчанию "Россия") - страна
- `street` (опционально) - улица

### Товар (ItemRequest)
- `quantity` (опционально, по умолчанию 1) - количество
- `weight` (обязательно) - вес в **килограммах**
- `size` (опционально) - размеры в **метрах**:
  - `length` - длина
  - `width` - ширина
  - `height` - высота

### Классы такси (taxi_classes)
- `express` - экспресс-доставка (быстрая)
- `courier` - курьерская доставка
- `cargo` - грузовая доставка

## Важно

⚠️ **Этот endpoint только рассчитывает стоимость, НЕ создает заказ на доставку!**

Для создания заказа на доставку нужно использовать отдельный endpoint (будет добавлен позже).

