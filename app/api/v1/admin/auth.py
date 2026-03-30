"""Админ-авторизация."""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from pydantic import BaseModel
from datetime import datetime

from app.database import get_db
from app.core.security import create_access_token
from app.services.user_service import UserService

router = APIRouter()


class LoginRequest(BaseModel):
    """Запрос на авторизацию."""

    username: str  # Может быть username или email
    password: str


class LoginResponse(BaseModel):
    """Ответ на авторизацию."""

    ok: bool
    access_token: str | None = None
    business_slug: str | None = None
    business_name: str | None = None
    message: str | None = None


@router.post("/login", response_model=LoginResponse)
async def login(
    request: LoginRequest,
    db: AsyncSession = Depends(get_db),
):
    """
    Авторизация владельца бизнеса по username/email и паролю.

    После успешной авторизации возвращает токен и информацию о бизнесе пользователя.
    """
    user_service = UserService(db)

    # Проверяем username/email и пароль
    user = await user_service.verify_user_password(request.username, request.password)

    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Неверный логин или пароль",
        )

    # Проверяем, что пользователь имеет роль owner или superadmin
    if user.role not in ["owner", "superadmin"]:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Недостаточно прав доступа",
        )

    # Получаем бизнес пользователя
    business = await user_service.get_user_business(user.id)

    if not business:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Бизнес не найден для данного пользователя",
        )

    # Обновляем last_login
    user.last_login = datetime.utcnow()
    await db.commit()

    # Создаем токен доступа с информацией о пользователе и бизнесе
    access_token = create_access_token(data={
        "user_id": str(user.id),
        "username": user.username,
        "role": user.role,
        "business_id": str(business.id),
        "business_slug": business.slug,
    })

    return LoginResponse(
        ok=True,
        access_token=access_token,
        business_slug=business.slug,
        business_name=business.name,
        message="Авторизация успешна",
    )


class RegisterRequest(BaseModel):
    """Запрос на регистрацию."""

    username: str
    password: str
    email: str | None = None
    business_name: str
    business_slug: str


class RegisterResponse(BaseModel):
    """Ответ на регистрацию."""

    ok: bool
    message: str
    user_id: str | None = None
    business_slug: str | None = None


@router.post("/register", response_model=RegisterResponse)
async def register(
    request: RegisterRequest,
    db: AsyncSession = Depends(get_db),
):
    """
    Регистрация нового владельца бизнеса.

    Создает пользователя и бизнес.
    """
    from app.services.user_service import UserService
    from app.services.business_service import BusinessService
    import uuid

    user_service = UserService(db)
    business_service = BusinessService(db)

    # Проверяем, не существует ли уже пользователь с таким username
    existing_user = await user_service.get_by_username(request.username)
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Пользователь с таким логином уже существует",
        )

    # Проверяем, не существует ли уже бизнес с таким slug
    existing_business = await business_service.get_by_slug(request.business_slug)
    if existing_business:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Бизнес с таким slug уже существует",
        )

    # Создаем пользователя
    user = await user_service.create_user(
        username=request.username,
        password=request.password,
        email=request.email,
        role="owner",
    )

    # Создаем бизнес
    business = await business_service.create(
        owner_id=user.id,
        name=request.business_name,
        slug=request.business_slug,
        description=None,
    )

    return RegisterResponse(
        ok=True,
        message="Регистрация успешна",
        user_id=str(user.id),
        business_slug=business.slug,
    )

