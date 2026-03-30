"""Сервис для геокодирования адресов через Яндекс Геокодер."""
import logging
import httpx
from typing import Optional, Tuple

logger = logging.getLogger(__name__)


class GeocoderService:
    """Сервис для преобразования адресов в координаты."""

    BASE_URL = "https://geocode-maps.yandex.ru/1.x/"

    def __init__(self, api_key: Optional[str] = None):
        self.api_key = api_key

    async def geocode(self, address: str) -> Optional[Tuple[float, float]]:
        """
        Преобразует адрес в координаты [долгота, широта].

        Args:
            address: Текстовый адрес

        Returns:
            Tuple[float, float] | None: Координаты [долгота, широта] или None
        """
        if not self.api_key:
            logger.warning("Yandex Geocoder API key not configured, using fallback")
            return None

        try:
            async with httpx.AsyncClient(timeout=10.0) as client:
                response = await client.get(
                    self.BASE_URL,
                    params={
                        "apikey": self.api_key,
                        "geocode": address,
                        "format": "json",
                    },
                )

                if response.status_code == 200:
                    data = response.json()
                    try:
                        geo_object = data["response"]["GeoObjectCollection"]["featureMember"][0]["GeoObject"]
                        pos = geo_object["Point"]["pos"].split()
                        lon = float(pos[0])
                        lat = float(pos[1])
                        logger.info(f"Geocoded '{address}' to [{lon}, {lat}]")
                        return (lon, lat)
                    except (KeyError, IndexError, ValueError) as e:
                        logger.error(f"Error parsing geocoder response: {e}")
                        return None
                else:
                    logger.error(f"Geocoder API error: {response.status_code}")
                    return None

        except Exception as e:
            logger.error(f"Error geocoding address '{address}': {e}", exc_info=True)
            return None

