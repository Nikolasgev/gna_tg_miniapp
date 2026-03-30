"""Dependencies для аутентификации."""
from typing import Any

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials

from app.core.security import decode_access_token

security = HTTPBearer()
security_optional = HTTPBearer(auto_error=False)


async def get_current_admin(
    credentials: HTTPAuthorizationCredentials = Depends(security),
) -> dict:
    """
    Проверка токена администратора/владельца бизнеса.
    
    Используется как dependency для защищенных эндпоинтов.
    Возвращает payload с информацией о пользователе и бизнесе.
    """
    token = credentials.credentials
    
    # Декодируем токен
    payload = decode_access_token(token)
    
    if payload is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Неверный или истекший токен",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    # Проверяем роль (owner или superadmin)
    role = payload.get("role")
    if role not in ["owner", "superadmin", "admin"]:  # admin для обратной совместимости
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Недостаточно прав доступа",
        )
    
    return payload


async def get_current_admin_optional(
    credentials: HTTPAuthorizationCredentials | None = Depends(security_optional),
) -> dict[str, Any] | None:
    """Как get_current_admin, но без ошибки если заголовка нет или токен невалиден."""
    if credentials is None:
        return None
    payload = decode_access_token(credentials.credentials)
    if payload is None:
        return None
    role = payload.get("role")
    if role not in ["owner", "superadmin", "admin"]:
        return None
    return payload

