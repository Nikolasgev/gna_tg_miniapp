"""Конфигурация приложения."""
import json
from typing import Any
from pydantic import field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Настройки приложения."""

    # Database
    database_url: str = "postgresql+asyncpg://postgres:postgres@localhost:5432/tg_store_db"

    # Redis
    redis_url: str = "redis://localhost:6379/0"

    # Security
    secret_key: str = "your-secret-key-change-in-production"
    admin_password: str = "admin123"  # Для начальной настройки

    # Telegram
    telegram_bot_token: str = ""

    # CORS
    cors_origins: list[str] = [
        "http://localhost:3000",
        "http://localhost:8080",
        "http://localhost:8081",
        "http://127.0.0.1:8080",
        "http://127.0.0.1:8081",
        # Добавляем IP-адреса для Telegram WebView
        "http://192.168.31.173:8000",
        "http://192.168.31.173:8080",
        "http://192.168.31.173:8081",
        # Разрешаем все origins в development (для удобства)
        # В production это должно быть строго ограничено
    ]

    @field_validator("cors_origins", mode="before")
    @classmethod
    def parse_cors_origins(cls, v: Any) -> list[str]:
        """Парсит cors_origins из строки в список."""
        if isinstance(v, str):
            # Пытаемся распарсить как JSON
            try:
                parsed = json.loads(v)
                if isinstance(parsed, list):
                    return parsed
            except (json.JSONDecodeError, TypeError):
                pass
            # Если не JSON, разделяем по запятой
            return [origin.strip() for origin in v.split(",") if origin.strip()]
        return v if isinstance(v, list) else []

    # Environment
    environment: str = "development"

    # Sentry (optional)
    sentry_dsn: str = ""

    # Payment Providers (optional)
    stripe_secret_key: str = ""
    stripe_webhook_secret: str = ""
    yookassa_shop_id: str = ""  # Shop ID из личного кабинета ЮKassa
    yookassa_secret_key: str = ""  # Secret Key (API ключ) из личного кабинета ЮKassa
    yookassa_webhook_secret: str = ""  # Секретный ключ для проверки подписи webhook

    # Delivery Providers (optional)
    yandex_delivery_token: str = ""  # API токен для Яндекс Доставки
    yandex_geocoder_api_key: str = ""  # API ключ для Яндекс Геокодера (опционально)
    dadata_api_key: str = ""  # API ключ для DaData (опционально, для автодополнения адресов)
    
    # Pickup address (адрес отправления для доставки)
    pickup_address_fullname: str = "Москва, 1-й проезд Марьиной Рощи, дом 7/9"
    pickup_address_coordinates: list[float] = [37.6000, 55.8000]  # [долгота, широта] - нужно уточнить через геокодер
    pickup_address_city: str = "Москва"
    pickup_address_country: str = "Россия"
    pickup_address_street: str = "1-й проезд Марьиной Рощи"

    @field_validator("pickup_address_coordinates", mode="before")
    @classmethod
    def parse_coordinates(cls, v: Any) -> list[float]:
        """Парсит координаты из строки в список float."""
        if isinstance(v, str):
            try:
                parsed = json.loads(v)
                if isinstance(parsed, list):
                    return [float(x) for x in parsed]
            except (json.JSONDecodeError, TypeError, ValueError):
                # Если не JSON, разделяем по запятой
                parts = [float(x.strip()) for x in v.split(",") if x.strip()]
                if len(parts) == 2:
                    return parts
        return v if isinstance(v, list) else [37.6000, 55.8000]

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra="ignore",
    )

    @property
    def is_development(self) -> bool:
        """Проверка, что это development окружение."""
        return self.environment == "development"

    @property
    def is_production(self) -> bool:
        """Проверка, что это production окружение."""
        return self.environment == "production"


settings = Settings()

