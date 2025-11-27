"""Сервис для работы с доставкой через Яндекс Доставку."""
import logging
import httpx
from typing import Optional, Dict, Any, List
from decimal import Decimal

from app.config import settings

logger = logging.getLogger(__name__)


class DeliveryService:
    """Сервис для расчета стоимости доставки через Яндекс Доставку."""

    BASE_URL = "https://b2b.taxi.yandex.net"
    CALCULATE_ENDPOINT = "/b2b/cargo/integration/v2/offers/calculate"

    def __init__(self):
        self.token = settings.yandex_delivery_token
        if not self.token:
            logger.warning("Yandex Delivery token not configured")

    async def calculate_delivery_cost(
        self,
        from_address: Dict[str, Any],  # {fullname, coordinates: [lon, lat], city, country, street}
        to_address: Dict[str, Any],  # {fullname, coordinates: [lon, lat], city, country, street}
        items: List[Dict[str, Any]],  # [{weight, size: {length, width, height}, quantity}]
        taxi_classes: Optional[List[str]] = None,  # ["courier", "express", "cargo"]
    ) -> Dict[str, Any]:
        """
        Рассчитать стоимость доставки через Яндекс Доставку.

        Args:
            from_address: Адрес отправления с координатами
            to_address: Адрес назначения с координатами
            items: Список товаров для доставки
            taxi_classes: Классы такси (courier, express, cargo)

        Returns:
            {
                "offers": [
                    {
                        "taxi_class": "courier",
                        "price": {
                            "total_price": "150.00",
                            "total_price_with_vat": "180.00",
                            "currency": "RUB"
                        },
                        "pickup_interval": {"from": "...", "to": "..."},
                        "delivery_interval": {"from": "...", "to": "..."},
                        "payload": "..."
                    }
                ]
            }

        Raises:
            ValueError: Если токен не настроен или произошла ошибка API
        """
        if not self.token:
            raise ValueError("Yandex Delivery token not configured")

        # Подготавливаем route_points
        route_points = [
            {
                "id": 1,
                "fullname": from_address.get("fullname", ""),
                "coordinates": from_address.get("coordinates", []),
                "city": from_address.get("city", ""),
                "country": from_address.get("country", "Россия"),
                "street": from_address.get("street", ""),
            },
            {
                "id": 2,
                "fullname": to_address.get("fullname", ""),
                "coordinates": to_address.get("coordinates", []),
                "city": to_address.get("city", ""),
                "country": to_address.get("country", "Россия"),
                "street": to_address.get("street", ""),
            },
        ]

        # Подготавливаем items с pickup_point и dropoff_point
        delivery_items = []
        for idx, item in enumerate(items, start=1):
            delivery_item = {
                "quantity": item.get("quantity", 1),
                "pickup_point": 1,  # ID точки отправления
                "dropoff_point": 2,  # ID точки назначения
                "weight": float(item.get("weight", 0.5)),  # Вес в килограммах
            }
            
            # Добавляем размеры, если указаны
            if "size" in item:
                size = item["size"]
                delivery_item["size"] = {
                    "length": float(size.get("length", 0.1)),  # В метрах
                    "width": float(size.get("width", 0.1)),
                    "height": float(size.get("height", 0.1)),
                }
            
            delivery_items.append(delivery_item)

        # Подготавливаем requirements
        requirements = {}
        if taxi_classes:
            requirements["taxi_classes"] = taxi_classes
        else:
            # По умолчанию используем courier
            requirements["taxi_classes"] = ["courier"]

        payload = {
            "items": delivery_items,
            "route_points": route_points,
            "requirements": requirements,
        }

        headers = {
            "Authorization": f"Bearer {self.token}",
            "Content-Type": "application/json",
            "Accept-Language": "ru-RU,ru;q=0.9,en-US;q=0.8,en;q=0.7",
        }

        url = f"{self.BASE_URL}{self.CALCULATE_ENDPOINT}"

        logger.info(f"Calculating delivery cost from {from_address.get('fullname')} to {to_address.get('fullname')}")
        logger.debug(f"Request payload: {payload}")

        try:
            async with httpx.AsyncClient(timeout=30.0) as client:
                response = await client.post(
                    url,
                    json=payload,
                    headers=headers,
                )

                if response.status_code == 200:
                    data = response.json()
                    logger.info(f"Delivery cost calculated successfully. Offers: {len(data.get('offers', []))}")
                    return data
                else:
                    error_text = response.text
                    logger.error(f"Yandex Delivery API error: {response.status_code} - {error_text}")
                    raise ValueError(f"Yandex Delivery API error: {response.status_code} - {error_text}")

        except httpx.TimeoutException:
            logger.error("Yandex Delivery API timeout")
            raise ValueError("Yandex Delivery API timeout")
        except httpx.RequestError as e:
            logger.error(f"Yandex Delivery API request error: {e}")
            raise ValueError(f"Yandex Delivery API request error: {e}")
        except Exception as e:
            logger.error(f"Unexpected error calculating delivery cost: {e}", exc_info=True)
            raise

