"""API для автодополнения адресов."""
import logging
import httpx
from typing import List, Optional
from fastapi import APIRouter, HTTPException, status, Query
from pydantic import BaseModel

logger = logging.getLogger(__name__)

router = APIRouter()


class AddressSuggestion(BaseModel):
    """Подсказка адреса."""
    value: str  # Полный адрес
    coordinates: Optional[List[float]] = None  # [долгота, широта]


class AddressSuggestionsResponse(BaseModel):
    """Ответ с подсказками адресов."""
    suggestions: List[AddressSuggestion]


@router.get("/suggest", response_model=AddressSuggestionsResponse)
async def suggest_addresses(
    query: str = Query(..., min_length=1, description="Текст для поиска адресов"),
    limit: int = Query(5, ge=1, le=10, description="Максимальное количество подсказок"),
):
    """
    Получить подсказки адресов через Яндекс Suggest API.
    
    Этот endpoint проксирует запросы к Яндекс Suggest API для автодополнения адресов.
    """
    if not query or len(query.strip()) < 1:
        return AddressSuggestionsResponse(suggestions=[])
    
    try:
        # Используем DaData Suggest API для автодополнения адресов
        # Документация: https://dadata.ru/api/suggest/address/
        # Для работы нужен API ключ, но можно использовать без ключа для тестирования
        # В production нужно добавить DADATA_API_KEY в настройки
        from app.config import settings
        
        dadata_url = "https://suggestions.dadata.ru/suggestions/api/4_1/rs/suggest/address"
        headers = {
            "Content-Type": "application/json",
            "Accept": "application/json",
        }
        
        # Если есть API ключ, добавляем его
        if hasattr(settings, 'dadata_api_key') and settings.dadata_api_key:
            headers["Authorization"] = f"Token {settings.dadata_api_key}"
        
        async with httpx.AsyncClient(timeout=10.0) as client:
            response = await client.post(
                dadata_url,
                headers=headers,
                json={
                    "query": query,
                    "count": limit,
                    "locations": [
                        {
                            "country": "Россия"
                        }
                    ],
                },
            )
            
            if response.status_code == 200:
                data = response.json()
                logger.debug(f"DaData API response keys: {data.keys() if isinstance(data, dict) else 'not a dict'}")
                suggestions = []
                
                # Парсим ответ от DaData API
                if "suggestions" in data:
                    logger.debug(f"Found {len(data['suggestions'])} suggestions in response")
                    for idx, suggestion_data in enumerate(data["suggestions"]):
                        logger.debug(f"Processing suggestion {idx}: keys={suggestion_data.keys() if isinstance(suggestion_data, dict) else 'not a dict'}")
                        if "value" in suggestion_data:
                            suggestion = AddressSuggestion(
                                value=suggestion_data["value"],
                            )
                            
                            # Извлекаем координаты, если они есть
                            if "data" in suggestion_data and isinstance(suggestion_data["data"], dict):
                                if "geo_lat" in suggestion_data["data"] and "geo_lon" in suggestion_data["data"]:
                                    try:
                                        lat = float(suggestion_data["data"]["geo_lat"])
                                        lon = float(suggestion_data["data"]["geo_lon"])
                                        suggestion.coordinates = [lon, lat]  # [долгота, широта]
                                        logger.debug(f"Added coordinates for suggestion {idx}: [{lon}, {lat}]")
                                    except (ValueError, TypeError) as e:
                                        logger.warning(f"Failed to parse coordinates for suggestion {idx}: {e}")
                            
                            suggestions.append(suggestion)
                            logger.debug(f"Added suggestion {idx}: {suggestion.value}")
                        else:
                            logger.warning(f"Suggestion {idx} missing 'value' key")
                else:
                    logger.warning(f"Response missing 'suggestions' key. Response keys: {data.keys() if isinstance(data, dict) else type(data)}")
                
                logger.info(f"Found {len(suggestions)} address suggestions for query: '{query}'")
                logger.debug(f"Returning suggestions: {[s.value for s in suggestions]}")
                return AddressSuggestionsResponse(suggestions=suggestions)
            elif response.status_code == 401 or response.status_code == 403:
                # DaData требует API ключ
                logger.warning(f"DaData API requires authentication. Status: {response.status_code}")
                logger.info("Returning empty suggestions. Please configure DADATA_API_KEY in .env")
                return AddressSuggestionsResponse(suggestions=[])
            else:
                logger.warning(f"DaData API returned status {response.status_code}: {response.text}")
                return AddressSuggestionsResponse(suggestions=[])
                
    except httpx.TimeoutException:
        logger.error("Timeout fetching address suggestions")
        raise HTTPException(
            status_code=status.HTTP_504_GATEWAY_TIMEOUT,
            detail="Таймаут при получении подсказок адресов",
        )
    except Exception as e:
        logger.error(f"Error fetching address suggestions: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Ошибка при получении подсказок адресов",
        )

