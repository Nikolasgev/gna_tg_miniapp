"""Telegram API."""
from fastapi import APIRouter, HTTPException, status
from pydantic import BaseModel

from app.core.telegram import extract_telegram_user
from app.config import settings

router = APIRouter()


class ValidateInitDataRequest(BaseModel):
    """Запрос на валидацию init_data."""

    init_data: str


class TelegramUser(BaseModel):
    """Модель пользователя Telegram."""

    id: int
    first_name: str
    username: str | None = None
    last_name: str | None = None
    language_code: str | None = None
    is_premium: bool | None = None


class ValidateInitDataResponse(BaseModel):
    """Ответ на валидацию init_data."""

    ok: bool
    telegram_user: TelegramUser | None = None


@router.post("/validate_init_data", response_model=ValidateInitDataResponse)
async def validate_init_data(request: ValidateInitDataRequest):
    """
    Валидация init_data от Telegram.

    Проверяет подпись через SHA256 HMAC + BOT_TOKEN.
    """
    if not settings.telegram_bot_token:
        # В режиме разработки без токена возвращаем mock данные
        if settings.is_development:
            return ValidateInitDataResponse(
                ok=True,
                telegram_user=TelegramUser(
                    id=123456789,
                    first_name="Test",
                    username="testuser",
                ),
            )
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Telegram bot token not configured",
        )
    
    # Валидируем init_data
    user_data = extract_telegram_user(request.init_data, settings.telegram_bot_token)
    
    if not user_data:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid init_data signature",
        )
    
    # Извлекаем данные пользователя
    telegram_user = TelegramUser(
        id=user_data.get("id"),
        first_name=user_data.get("first_name", ""),
        username=user_data.get("username"),
        last_name=user_data.get("last_name"),
        language_code=user_data.get("language_code"),
        is_premium=user_data.get("is_premium", False),
    )
    
    return ValidateInitDataResponse(
        ok=True,
        telegram_user=telegram_user,
    )
