"""Конфигурация приложения."""
from typing import Self

from pydantic import field_validator, model_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Настройки приложения."""

    # Database
    database_url: str = "postgresql+asyncpg://postgres:postgres@localhost:5432/tg_store_db"

    # Redis
    redis_url: str = "redis://localhost:6379/0"

    @field_validator("database_url", mode="after")
    @classmethod
    def convert_database_url(cls, v: str) -> str:
        """Конвертируем postgresql:// в postgresql+asyncpg:// для asyncpg."""
        if v.startswith("postgresql://") and "+asyncpg" not in v:
            return v.replace("postgresql://", "postgresql+asyncpg://", 1)
        return v

    # Security
    secret_key: str = "your-secret-key-change-in-production"
    admin_password: str = "admin123"  # Для начальной настройки

    # Telegram
    telegram_bot_token: str = ""

    # CORS
    cors_origins: list[str] = [
        "*",  # В development разрешаем все origins для удобства разработки
        # В production это должно быть строго ограничено конкретными доменами
        "http://localhost:3000",
        "http://localhost:8080",
        "http://localhost:8081",
        "http://127.0.0.1:8080",
        "http://127.0.0.1:8081",
        # Добавляем IP-адреса для Telegram WebView
        "http://192.168.31.173:8000",
        "http://192.168.31.173:8080",
        "http://192.168.31.173:8081",
        # GitHub Pages (Mini App)
        "https://nikolasgev.github.io",
    ]

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

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra="ignore",
    )

    @model_validator(mode="after")
    def validate_production_security(self) -> Self:
        """В production запрещаем дефолтные секреты и CORS *."""
        if not self.is_production:
            return self
        if self.secret_key in ("", "your-secret-key-change-in-production") or len(self.secret_key) < 32:
            raise ValueError(
                "Для ENVIRONMENT=production задайте SECRET_KEY (не короче 32 символов), "
                "не равный значению по умолчанию."
            )
        if self.admin_password in ("", "admin123"):
            raise ValueError(
                "Для ENVIRONMENT=production задайте ADMIN_PASSWORD, отличный от значения по умолчанию."
            )
        if "*" in self.cors_origins or self.cors_origins == ["*"]:
            raise ValueError(
                "Для ENVIRONMENT=production укажите явный CORS_ORIGINS (без '*'). "
                "Список доменов Mini App и админки."
            )
        return self

    @property
    def is_development(self) -> bool:
        """Проверка, что это development окружение."""
        return self.environment.lower() == "development"

    @property
    def is_production(self) -> bool:
        """Проверка, что это production окружение."""
        return self.environment.lower() == "production"


settings = Settings()

