"""Модель бизнеса."""
import uuid
from datetime import datetime
from typing import TYPE_CHECKING

from sqlalchemy import String, Text, ForeignKey, Numeric
from sqlalchemy.orm import Mapped, mapped_column, relationship
from decimal import Decimal

from app.database import Base

if TYPE_CHECKING:
    from app.models.promocode import Promocode
    from app.models.loyalty import LoyaltyAccount


class Business(Base):
    """Модель бизнеса."""

    __tablename__ = "businesses"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    owner_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id"), nullable=False)
    name: Mapped[str] = mapped_column(String, nullable=False)
    slug: Mapped[str] = mapped_column(String, unique=True, nullable=False, index=True)
    description: Mapped[str | None] = mapped_column(Text, nullable=True)
    timezone: Mapped[str | None] = mapped_column(String, nullable=True)
    currency: Mapped[str] = mapped_column(String(3), default="RUB")
    loyalty_points_percent: Mapped[Decimal] = mapped_column(Numeric(5, 2), default=Decimal("1.00"), nullable=False)  # Процент начисления баллов (по умолчанию 1%)
    created_at: Mapped[datetime] = mapped_column(default=datetime.utcnow)
    updated_at: Mapped[datetime] = mapped_column(default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationships
    owner: Mapped["User"] = relationship("User", foreign_keys=[owner_id])
    products: Mapped[list["Product"]] = relationship("Product", back_populates="business")
    orders: Mapped[list["Order"]] = relationship("Order", back_populates="business")
    promocodes: Mapped[list["Promocode"]] = relationship("Promocode", back_populates="business")
    loyalty_accounts: Mapped[list["LoyaltyAccount"]] = relationship("LoyaltyAccount", back_populates="business")

