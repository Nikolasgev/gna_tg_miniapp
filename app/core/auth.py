"""Dependencies для аутентификации."""
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials

from app.core.security import decode_access_token

security = HTTPBearer()


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

