"""Тестовый скрипт для проверки API Яндекс Доставки."""
import asyncio
import httpx
import json
import uuid
from datetime import datetime, timedelta


# Токен из документации
YANDEX_DELIVERY_TOKEN = "y0__xDM95PGCBix9Bwgr92pqRW1TAdT6TUjQQi-z-uuF7EexLX9zA"
# Используем продакшн хост (для тестового окружения: https://b2b.taxi.tst.yandex.net)
BASE_URL = "https://b2b.taxi.yandex.net"


async def test_offers_calculate():
    """Тест запроса на расчет вариантов доставки."""
    
    # Товары для доставки (согласно документации)
    items = [
        {
            "quantity": 1,  # Количество единиц товара
            "pickup_point": 1,  # ID точки отправления (int64)
            "dropoff_point": 2,  # ID точки назначения (int64)
            "weight": 0.5,  # Вес в килограммах (не граммах!)
            "size": {
                "length": 0.1,  # Длина в метрах (не сантиметрах!)
                "width": 0.1,   # Ширина в метрах
                "height": 0.1,  # Высота в метрах
            },
        },
    ]
    
    # Маршрут доставки (согласно документации RoutePointWithAddress)
    route_points = [
        {
            "id": 1,  # ID точки (int64) - обязателен если несколько точек
            "fullname": "Москва, Красная площадь, 1",
            "coordinates": [37.6173, 55.7558],  # [долгота, широта]
            "city": "Москва",
            "country": "Россия",
            "street": "Красная площадь",
        },
        {
            "id": 2,  # ID точки (int64)
            "fullname": "Москва, Тверская улица, 10",
            "coordinates": [37.6064, 55.7558],  # [долгота, широта]
            "city": "Москва",
            "country": "Россия",
            "street": "Тверская улица",
        },
    ]
    
    # Требования к доставке (опционально)
    requirements = {
        "taxi_classes": ["express"],  # Массив классов: courier, express, cargo
    }
    
    # Данные для запроса
    payload = {
        "items": items,
        "route_points": route_points,
        "requirements": requirements,  # Опционально
    }
    
    headers = {
        "Authorization": f"Bearer {YANDEX_DELIVERY_TOKEN}",
        "Content-Type": "application/json",
        "Accept-Language": "ru-RU,ru;q=0.9,en-US;q=0.8,en;q=0.7",
    }
    
    print("=" * 60)
    print("Тест API Яндекс Доставки")
    print("=" * 60)
    print(f"\n📤 Отправка запроса на расчет доставки...")
    endpoint = "/b2b/cargo/integration/v2/offers/calculate"
    url = f"{BASE_URL}{endpoint}"
    print(f"URL: {url}")
    print(f"\nДанные запроса:")
    print(json.dumps(payload, ensure_ascii=False, indent=2))
    
    async with httpx.AsyncClient(timeout=30.0) as client:
        try:
            print(f"\n📡 Запрос к: {url}")
            response = await client.post(
                url,
                json=payload,
                headers=headers,
            )
        
            print(f"\n📥 Ответ от API:")
            print(f"Status Code: {response.status_code}")
            
            if response.status_code == 200:
                data = response.json()
                print(f"\n✅ Успешный ответ:")
                print(json.dumps(data, ensure_ascii=False, indent=2))
                
                # Парсим варианты доставки
                if "offers" in data:
                    print(f"\n📦 Найдено вариантов доставки: {len(data['offers'])}")
                    for i, offer in enumerate(data["offers"], 1):
                        print(f"\nВариант {i}:")
                        print(f"  - Тариф: {offer.get('taxi_class', 'N/A')}")
                        price = offer.get('price', {})
                        if isinstance(price, dict):
                            print(f"  - Цена: {price.get('total_price', 'N/A')} {price.get('currency', 'RUB')}")
                            print(f"  - Цена с НДС: {price.get('total_price_with_vat', 'N/A')} {price.get('currency', 'RUB')}")
                        pickup = offer.get('pickup_interval', {})
                        delivery = offer.get('delivery_interval', {})
                        print(f"  - Забор: {pickup.get('from', 'N/A')} - {pickup.get('to', 'N/A')}")
                        print(f"  - Доставка: {delivery.get('from', 'N/A')} - {delivery.get('to', 'N/A')}")
                        print(f"  - Payload: {offer.get('payload', 'N/A')[:50]}...")
                else:
                    print("\n⚠️ Варианты доставки не найдены в ответе")
            else:
                print(f"\n❌ Ошибка {response.status_code}:")
                print(f"Response Text: {response.text}")
                try:
                    error_data = response.json()
                    print(f"Error JSON:")
                    print(json.dumps(error_data, ensure_ascii=False, indent=2))
                except:
                    pass
                    
        except httpx.TimeoutException:
            print("\n❌ Таймаут запроса (превышено 30 секунд)")
        except httpx.RequestError as e:
            print(f"\n❌ Ошибка запроса: {e}")
        except Exception as e:
            print(f"\n❌ Неожиданная ошибка: {e}")
            import traceback
            traceback.print_exc()


async def test_claims_create():
    """Тест создания заявки на доставку."""
    print("\n" + "=" * 60)
    print("Тест создания заявки через claims/create")
    print("=" * 60)
    
    platform_station_id = "fbed3aa1-2cc6-4370-ab4d-59c5cc9bb924"
    
    payload = {
        "platform_station_id": platform_station_id,
        "items": [
            {
                "title": "Кофе",
                "quantity": 1,
                "cost_value": "200",
                "cost_currency": "RUB",
                "weight": 500,  # Вес в граммах - обязателен если нет requirements
                "pickup_point": 0,  # point_id точки отправления (source)
                "dropoff_point": 1,  # point_id точки назначения (destination)
            },
        ],
        "route_points": [
            {
                "point_id": 0,  # Уникальный ID точки
                "visit_order": 1,  # Порядок посещения (1 = первая точка)
                "address": {
                    "fullname": "Москва, ул. Ленина, д. 1",
                    "coordinates": [37.6173, 55.7558],
                },
                "contact": {
                    "name": "Иван Иванов",
                    "phone": "+79161234567",
                },
                "type": "source",
            },
            {
                "point_id": 1,  # Уникальный ID точки
                "visit_order": 2,  # Порядок посещения (2 = вторая точка)
                "address": {
                    "fullname": "Москва, ул. Пушкина, д. 10",
                    "coordinates": [37.6200, 55.7522],
                },
                "contact": {
                    "name": "Петр Петров",
                    "phone": "+79161234568",
                },
                "type": "destination",
            },
        ],
        "emergency_contact": {
            "name": "Сергей Сергеев",
            "phone": "+79161234569",
        },
        "comment": "Доставить как можно скорее",
        "requirements": {
            "cargo_type": "lcv_m",  # Тип машины для грузовой доставки
            "cargo_loaders": 0,  # Количество грузчиков
        },
    }
    
    headers = {
        "Authorization": f"Bearer {YANDEX_DELIVERY_TOKEN}",
        "Content-Type": "application/json",
        "Accept-Language": "ru-RU,ru;q=0.9,en-US;q=0.8,en;q=0.7",
    }
    
    endpoints = [
        "/api/b2b/platform/claims/create",
        "/b2b/cargo/integration/v2/claims/create",
    ]
    
    print(f"\n📤 Создание заявки на доставку...")
    print(json.dumps(payload, ensure_ascii=False, indent=2))
    
    async with httpx.AsyncClient(timeout=30.0) as client:
        for endpoint in endpoints:
            # Генерируем уникальный request_id для claims/create
            request_id = str(uuid.uuid4())
            url = f"{BASE_URL}{endpoint}?request_id={request_id}"
            try:
                print(f"\n📡 Запрос к: {url}")
                print(f"Request ID: {request_id}")
                response = await client.post(
                    url,
                    json=payload,
                    headers=headers,
                )
                
                print(f"\n📥 Ответ от API:")
                print(f"Status Code: {response.status_code}")
                
                if response.status_code in [200, 201]:
                    data = response.json()
                    print(f"\n✅ Заявка создана успешно:")
                    print(json.dumps(data, ensure_ascii=False, indent=2))
                    
                    # Сохраняем claim_id для дальнейших тестов
                    if "id" in data:
                        claim_id = data["id"]
                        print(f"\n📋 Claim ID: {claim_id}")
                        return claim_id
                    break
                else:
                    print(f"❌ Ошибка {response.status_code}: {response.text[:500]}")
                    continue
                    
            except Exception as e:
                print(f"❌ Ошибка для {endpoint}: {e}")
                continue
    
    return None


async def test_claims_info(claim_id: str | None = None):
    """Тест получения информации о заявке."""
    if not claim_id:
        print("\n⚠️ Нет claim_id для теста claims/info")
        return
    
    print("\n" + "=" * 60)
    print(f"Тест получения информации о заявке: {claim_id}")
    print("=" * 60)
    
    headers = {
        "Authorization": f"Bearer {YANDEX_DELIVERY_TOKEN}",
        "Accept-Language": "ru-RU,ru;q=0.9,en-US;q=0.8,en;q=0.7",
    }
    
    endpoints = [
        f"/api/b2b/platform/claims/{claim_id}",
        f"/b2b/cargo/integration/v2/claims/{claim_id}",
    ]
    
    async with httpx.AsyncClient(timeout=30.0) as client:
        for endpoint in endpoints:
            url = f"{BASE_URL}{endpoint}"
            try:
                print(f"\n📡 Запрос к: {url}")
                response = await client.get(url, headers=headers)
                
                print(f"Status Code: {response.status_code}")
                if response.status_code == 200:
                    data = response.json()
                    print(f"\n✅ Информация о заявке:")
                    print(json.dumps(data, ensure_ascii=False, indent=2))
                    break
                else:
                    print(f"❌ Ошибка: {response.text[:500]}")
            except Exception as e:
                print(f"❌ Ошибка: {e}")


if __name__ == "__main__":
    print("\n🚀 Запуск тестов API Яндекс Доставки\n")
    
    # Тест расчета доставки
    asyncio.run(test_offers_calculate())
    
    # Тест создания заявки
    claim_id = asyncio.run(test_claims_create())
    
    # Тест получения информации о заявке
    if claim_id:
        asyncio.run(test_claims_info(claim_id))

