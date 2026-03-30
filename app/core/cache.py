"""Кэширование через Redis."""
import json
from typing import Any, Optional
import redis.asyncio as redis
from app.config import settings


class CacheService:
    """Сервис для работы с кэшем Redis."""

    def __init__(self):
        self._redis: Optional[redis.Redis] = None

    async def connect(self):
        """Подключение к Redis."""
        if not self._redis:
            try:
                self._redis = await redis.from_url(
                    settings.redis_url,
                    encoding="utf-8",
                    decode_responses=True,
                )
                # Проверяем подключение
                await self._redis.ping()
            except Exception:
                # Если Redis недоступен, продолжаем без кэша
                self._redis = None

    async def disconnect(self):
        """Отключение от Redis."""
        if self._redis:
            await self._redis.close()
            self._redis = None

    async def get(self, key: str) -> Any | None:
        """Получить значение из кэша."""
        if not self._redis:
            try:
                await self.connect()
            except Exception:
                return None

        if not self._redis:
            return None

        try:
            value = await self._redis.get(key)
            if value:
                return json.loads(value)
            return None
        except Exception:
            return None

    async def set(self, key: str, value: Any, ttl: int = 300) -> bool:
        """Установить значение в кэш."""
        if not self._redis:
            try:
                await self.connect()
            except Exception:
                return False

        if not self._redis:
            return False

        try:
            serialized = json.dumps(value, default=str)
            await self._redis.setex(key, ttl, serialized)
            return True
        except Exception:
            return False

    async def delete(self, key: str) -> bool:
        """Удалить значение из кэша."""
        if not self._redis:
            try:
                await self.connect()
            except Exception:
                return False

        if not self._redis:
            return False

        try:
            await self._redis.delete(key)
            return True
        except Exception:
            return False

    async def delete_pattern(self, pattern: str) -> int:
        """Удалить все ключи по паттерну."""
        if not self._redis:
            try:
                await self.connect()
            except Exception:
                return 0

        if not self._redis:
            return 0

        try:
            keys = await self._redis.keys(pattern)
            if keys:
                return await self._redis.delete(*keys)
            return 0
        except Exception:
            return 0


# Глобальный экземпляр
cache_service = CacheService()


def get_cache_key_products(business_slug: str, category_id: str | None = None, search: str | None = None, min_price: str | None = None, max_price: str | None = None, page: int = 1, limit: int = 20) -> str:
    """Генерация ключа кэша для списка продуктов."""
    parts = [f"products:{business_slug}"]
    if category_id:
        parts.append(f"cat:{category_id}")
    if search:
        parts.append(f"q:{search}")
    if min_price:
        parts.append(f"min_price:{min_price}")
    if max_price:
        parts.append(f"max_price:{max_price}")
    parts.append(f"page:{page}")
    parts.append(f"limit:{limit}")
    return ":".join(parts)


def get_cache_key_categories(business_slug: str) -> str:
    """Генерация ключа кэша для категорий."""
    return f"categories:{business_slug}"


def get_cache_key_business(slug: str) -> str:
    """Генерация ключа кэша для бизнеса."""
    return f"business:{slug}"


def get_cache_key_business_settings(slug: str) -> str:
    """Генерация ключа кэша для настроек бизнеса."""
    return f"business_settings:{slug}"

