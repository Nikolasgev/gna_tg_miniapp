"""Проверка подлинности Telegram WebApp init_data для защищённых эндпоинтов Mini App."""
from __future__ import annotations

from fastapi import Header, HTTPException, status

from app.config import settings
from app.core.telegram import extract_telegram_user


def get_telegram_user_id_from_init_data(init_data: str | None) -> int | None:
    """
    Извлечь telegram user id из init_data (строка из Telegram.WebApp.initData).

    Returns:
        int при успешной валидации, None если данных нет или подпись неверна.
    """
    if init_data is None or not str(init_data).strip():
        # Как validate_init_data: без токена в development допускаем мок-пользователя
        if not settings.telegram_bot_token and settings.is_development:
            return 123456789
        return None

    if not settings.telegram_bot_token:
        if settings.is_development:
            return 123456789
        return None

    user_data = extract_telegram_user(init_data.strip(), settings.telegram_bot_token)
    if not user_data or user_data.get("id") is None:
        return None
    return int(user_data["id"])


async def require_telegram_identity(
    x_telegram_init_data: str | None = Header(None, alias="X-Telegram-Init-Data"),
) -> int:
    """Dependency: заголовок X-Telegram-Init-Data обязателен; возвращает telegram user id."""
    if x_telegram_init_data is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Требуется заголовок X-Telegram-Init-Data",
        )
    uid = get_telegram_user_id_from_init_data(x_telegram_init_data)
    if uid is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Невалидные данные Telegram WebApp в X-Telegram-Init-Data",
        )
    return uid
