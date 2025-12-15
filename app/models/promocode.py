"""Модель промокода."""
import uuid
from datetime import datetime
from decimal import Decimal

from sqlalchemy import String, Numeric, Boolean, ForeignKey, Integer, BigInteger, DateTime, Text
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from app.models.business import Business
    from app.models.order import Order
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base


class Promocode(Base):
    """Модель промокода."""

    __tablename__ = "promocodes"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    business_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("businesses.id"), nullable=False, index=True)
    code: Mapped[str] = mapped_column(String(50), nullable=False, unique=True, index=True)
    description: Mapped[str | None] = mapped_column(Text, nullable=True)
    
    # Тип скидки: 'percentage' (процент) или 'fixed' (фиксированная сумма)
    discount_type: Mapped[str] = mapped_column(String(20), nullable=False, default="percentage")
    # Значение скидки (процент от 0 до 100 или фиксированная сумма)
    discount_value: Mapped[Decimal] = mapped_column(Numeric(10, 2), nullable=False)
    
    # Минимальная сумма заказа для применения промокода
    min_order_amount: Mapped[Decimal | None] = mapped_column(Numeric(10, 2), nullable=True)
    
    # Максимальная сумма скидки (для процентных промокодов)
    max_discount_amount: Mapped[Decimal | None] = mapped_column(Numeric(10, 2), nullable=True)
    
    # Количество использований
    max_uses: Mapped[int | None] = mapped_column(Integer, nullable=True)  # None = без ограничений
    uses_count: Mapped[int] = mapped_column(Integer, default=0)
    
    # Лимит использований на одного пользователя
    max_uses_per_user: Mapped[int | None] = mapped_column(Integer, nullable=True, default=1)
    
    # Даты действия
    valid_from: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    valid_until: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    
    # Активность
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    
    created_at: Mapped[datetime] = mapped_column(default=datetime.utcnow)
    updated_at: Mapped[datetime] = mapped_column(default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationships
    business: Mapped["Business"] = relationship("Business", back_populates="promocodes")
    usages: Mapped[list["PromocodeUsage"]] = relationship("PromocodeUsage", back_populates="promocode")


class PromocodeUsage(Base):
    """Модель использования промокода."""

    __tablename__ = "promocode_usages"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    promocode_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("promocodes.id"), nullable=False, index=True)
    order_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("orders.id"), nullable=False, index=True)
    user_telegram_id: Mapped[int | None] = mapped_column(BigInteger, nullable=True, index=True)
    
    # Сумма скидки, применённая к заказу
    discount_amount: Mapped[Decimal] = mapped_column(Numeric(10, 2), nullable=False)
    
    # Сумма заказа до применения промокода
    order_amount_before: Mapped[Decimal] = mapped_column(Numeric(10, 2), nullable=False)
    
    # Сумма заказа после применения промокода
    order_amount_after: Mapped[Decimal] = mapped_column(Numeric(10, 2), nullable=False)
    
    created_at: Mapped[datetime] = mapped_column(default=datetime.utcnow)

    # Relationships
    promocode: Mapped["Promocode"] = relationship("Promocode", back_populates="usages")
    order: Mapped["Order"] = relationship("Order", back_populates="promocode_usages")

