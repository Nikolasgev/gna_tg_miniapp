"""Модели заказов."""
import uuid
from datetime import datetime
from decimal import Decimal
from typing import TYPE_CHECKING

from sqlalchemy import String, Text, Numeric, BigInteger, ForeignKey, JSON
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base

if TYPE_CHECKING:
    from app.models.promocode import Promocode, PromocodeUsage
    from app.models.loyalty import LoyaltyTransaction


class Order(Base):
    """Модель заказа."""

    __tablename__ = "orders"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    business_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("businesses.id"), nullable=False)
    user_telegram_id: Mapped[int | None] = mapped_column(BigInteger, nullable=True)
    customer_name: Mapped[str] = mapped_column(String, nullable=False)
    customer_phone: Mapped[str] = mapped_column(String, nullable=False)
    customer_address: Mapped[str | None] = mapped_column(Text, nullable=True)
    total_amount: Mapped[Decimal] = mapped_column(Numeric(10, 2), nullable=False)
    currency: Mapped[str] = mapped_column(String, default="RUB")
    
    # Поля для промокодов и скидок
    subtotal_amount: Mapped[Decimal | None] = mapped_column(Numeric(10, 2), nullable=True)  # Сумма до скидок
    discount_amount: Mapped[Decimal | None] = mapped_column(Numeric(10, 2), nullable=True)  # Общая сумма скидки
    promocode_id: Mapped[uuid.UUID | None] = mapped_column(ForeignKey("promocodes.id"), nullable=True)
    
    # Поля для программы лояльности
    loyalty_points_earned: Mapped[Decimal | None] = mapped_column(Numeric(10, 2), nullable=True)  # Баллы, заработанные за заказ
    loyalty_points_spent: Mapped[Decimal | None] = mapped_column(Numeric(10, 2), nullable=True)  # Баллы, потраченные на заказ
    
    status: Mapped[str] = mapped_column(String, default="new")  # new / accepted / preparing / ready / cancelled / completed
    payment_status: Mapped[str] = mapped_column(String, default="pending")  # pending / paid / failed / refunded
    payment_method: Mapped[str] = mapped_column(String, nullable=False)  # cash / online
    order_metadata: Mapped[dict | None] = mapped_column(JSON, nullable=True)  # Переименовано из metadata (зарезервированное слово)
    created_at: Mapped[datetime] = mapped_column(default=datetime.utcnow)
    updated_at: Mapped[datetime] = mapped_column(default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationships
    business: Mapped["Business"] = relationship("Business", back_populates="orders")
    items: Mapped[list["OrderItem"]] = relationship("OrderItem", back_populates="order")
    promocode: Mapped["Promocode | None"] = relationship("Promocode", foreign_keys=[promocode_id])
    promocode_usages: Mapped[list["PromocodeUsage"]] = relationship("PromocodeUsage", back_populates="order")
    loyalty_transactions: Mapped[list["LoyaltyTransaction"]] = relationship("LoyaltyTransaction", back_populates="order")


class OrderItem(Base):
    """Модель элемента заказа."""

    __tablename__ = "order_items"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    order_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("orders.id"), nullable=False)
    product_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("products.id"), nullable=False)
    title_snapshot: Mapped[str] = mapped_column(String, nullable=False)
    quantity: Mapped[int] = mapped_column(nullable=False)
    unit_price: Mapped[Decimal] = mapped_column(Numeric(10, 2), nullable=False)
    total_price: Mapped[Decimal] = mapped_column(Numeric(10, 2), nullable=False)

    # Relationships
    order: Mapped["Order"] = relationship("Order", back_populates="items")
    product: Mapped["Product"] = relationship("Product", back_populates="order_items")

