"""API для расчета стоимости доставки."""
from fastapi import APIRouter, HTTPException, status
from pydantic import BaseModel, Field
from typing import List, Optional, Dict, Any
import logging

from app.services.delivery_service import DeliveryService

logger = logging.getLogger(__name__)

router = APIRouter()


class AddressRequest(BaseModel):
    """Адрес для расчета доставки."""
    fullname: str = Field(..., description="Полный адрес")
    coordinates: List[float] = Field(..., description="Координаты [долгота, широта]")
    city: str = Field(..., description="Город")
    country: str = Field(default="Россия", description="Страна")
    street: Optional[str] = Field(None, description="Улица")


class ItemRequest(BaseModel):
    """Товар для доставки."""
    quantity: int = Field(default=1, description="Количество")
    weight: float = Field(..., description="Вес в килограммах")
    size: Optional[Dict[str, float]] = Field(
        None,
        description="Размеры в метрах: {length, width, height}",
    )


class CalculateDeliveryRequest(BaseModel):
    """Запрос на расчет стоимости доставки."""
    from_address: AddressRequest = Field(..., description="Адрес отправления")
    to_address: AddressRequest = Field(..., description="Адрес назначения")
    items: List[ItemRequest] = Field(..., description="Список товаров для доставки")
    taxi_classes: Optional[List[str]] = Field(
        None,
        description="Классы такси: courier, express, cargo",
    )


@router.post("/calculate", response_model=Dict[str, Any])
async def calculate_delivery_cost(request: CalculateDeliveryRequest):
    """
    Рассчитать стоимость доставки через Яндекс Доставку.

    Этот endpoint только рассчитывает стоимость, НЕ создает заказ на доставку.

    Пример запроса:
    ```json
    {
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
        "taxi_classes": ["courier"]
    }
    ```

    Пример ответа:
    ```json
    {
        "offers": [
            {
                "taxi_class": "courier",
                "price": {
                    "total_price": "150.00",
                    "total_price_with_vat": "180.00",
                    "currency": "RUB"
                },
                "pickup_interval": {
                    "from": "2024-01-01T10:00:00+03:00",
                    "to": "2024-01-01T10:30:00+03:00"
                },
                "delivery_interval": {
                    "from": "2024-01-01T11:00:00+03:00",
                    "to": "2024-01-01T11:30:00+03:00"
                }
            }
        ]
    }
    ```
    """
    logger.info("=== Delivery cost calculation request ===")
    logger.info(f"From: {request.from_address.fullname}")
    logger.info(f"To: {request.to_address.fullname}")
    logger.info(f"Items: {len(request.items)}")

    try:
        service = DeliveryService()
        
        # Преобразуем Pydantic модели в словари
        from_address_dict = request.from_address.model_dump()
        to_address_dict = request.to_address.model_dump()
        items_dict = [item.model_dump() for item in request.items]

        result = await service.calculate_delivery_cost(
            from_address=from_address_dict,
            to_address=to_address_dict,
            items=items_dict,
            taxi_classes=request.taxi_classes,
        )

        logger.info(f"✅ Delivery cost calculated successfully. Offers: {len(result.get('offers', []))}")
        return result

    except ValueError as e:
        logger.error(f"❌ Error calculating delivery cost: {e}")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e),
        )
    except Exception as e:
        logger.error(f"❌ Unexpected error: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Internal server error: {str(e)}",
        )

