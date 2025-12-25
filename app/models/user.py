"""Модель пользователя."""
import uuid
from datetime import datetime

from sqlalchemy import String, BigInteger
from sqlalchemy.orm import Mapped, mapped_column

from app.database import Base


class User(Base):
    """Модель пользователя."""

    __tablename__ = "users"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    username: Mapped[str | None] = mapped_column(String, unique=True, nullable=True)  # Логин для входа в админку
    password_hash: Mapped[str | None] = mapped_column(String, nullable=True)  # Хешированный пароль
    firebase_uid: Mapped[str | None] = mapped_column(String, unique=True, nullable=True)
    telegram_id: Mapped[int | None] = mapped_column(BigInteger, unique=True, nullable=True)
    email: Mapped[str | None] = mapped_column(String, unique=True, nullable=True)
    role: Mapped[str] = mapped_column(String, nullable=False)  # superadmin / owner / staff / client
    created_at: Mapped[datetime] = mapped_column(default=datetime.utcnow)
    updated_at: Mapped[datetime] = mapped_column(default=datetime.utcnow, onupdate=datetime.utcnow)
    last_login: Mapped[datetime | None] = mapped_column(nullable=True)

