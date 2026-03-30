"""Сервис для работы с пользователями."""
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload
import uuid

from app.core.security import verify_password, get_password_hash
from app.models.user import User
from app.models.business import Business


class UserService:
    """Сервис для работы с пользователями."""

    def __init__(self, db: AsyncSession):
        self.db = db

    async def get_by_username(self, username: str) -> User | None:
        """Получить пользователя по username."""
        stmt = select(User).where(User.username == username)
        result = await self.db.execute(stmt)
        return result.scalar_one_or_none()

    async def get_by_email(self, email: str) -> User | None:
        """Получить пользователя по email."""
        stmt = select(User).where(User.email == email)
        result = await self.db.execute(stmt)
        return result.scalar_one_or_none()

    async def verify_user_password(self, username_or_email: str, password: str) -> User | None:
        """
        Проверить пароль пользователя.
        
        Возвращает User если пароль верный, иначе None.
        """
        # Пытаемся найти по username или email
        user = await self.get_by_username(username_or_email)
        if not user:
            user = await self.get_by_email(username_or_email)
        
        if not user:
            return None
        
        if not user.password_hash:
            return None
        
        if verify_password(password, user.password_hash):
            return user
        
        return None

    async def get_user_business(self, user_id: uuid.UUID) -> Business | None:
        """Получить бизнес пользователя (где он owner)."""
        stmt = select(Business).where(Business.owner_id == user_id)
        result = await self.db.execute(stmt)
        return result.scalar_one_or_none()

    async def create_user(
        self,
        username: str,
        password: str,
        email: str | None = None,
        role: str = "owner",
    ) -> User:
        """Создать нового пользователя."""
        password_hash = get_password_hash(password)
        
        user = User(
            username=username,
            password_hash=password_hash,
            email=email,
            role=role,
        )
        self.db.add(user)
        await self.db.commit()
        await self.db.refresh(user)
        return user

    async def update_password(self, user_id: uuid.UUID, new_password: str) -> None:
        """Обновить пароль пользователя."""
        user = await self.db.get(User, user_id)
        if user:
            user.password_hash = get_password_hash(new_password)
            await self.db.commit()

