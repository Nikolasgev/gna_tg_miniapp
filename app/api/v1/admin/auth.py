"""Админ-авторизация."""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from pydantic import BaseModel

from app.database import get_db
from app.core.security import verify_password, create_access_token
from app.services.admin_service import AdminService

router = APIRouter()


class LoginRequest(BaseModel):
    """Запрос на авторизацию."""

    password: str


class LoginResponse(BaseModel):
    """Ответ на авторизацию."""

    ok: bool
    access_token: str | None = None
    message: str | None = None


@router.post("/login", response_model=LoginResponse)
async def login(
    request: LoginRequest,
    db: AsyncSession = Depends(get_db),
):
    """
    Авторизация администратора по паролю.

    Пароль проверяется в таблице settings с ключом 'admin_password'.
    """
    admin_service = AdminService(db)

    # Проверяем пароль
    is_valid = await admin_service.verify_password(request.password)

    if not is_valid:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Неверный пароль",
        )

    # Создаем токен доступа
    access_token = create_access_token(data={"role": "admin"})

    return LoginResponse(
        ok=True,
        access_token=access_token,
        message="Авторизация успешна",
    )

