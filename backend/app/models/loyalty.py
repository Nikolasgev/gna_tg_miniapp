"""Модели программы лояльности."""
import uuid
from datetime import datetime
from decimal import Decimal

from sqlalchemy import String, Numeric, Boolean, ForeignKey, BigInteger, Integer, DateTime, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship
from typing import TYPE_CHECKING

from app.database import Base

if TYPE_CHECKING:
    from app.models.business import Business
    from app.models.order import Order


class LoyaltyAccount(Base):
    """Модель аккаунта программы лояльности пользователя."""

    __tablename__ = "loyalty_accounts"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    business_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("businesses.id"), nullable=False, index=True)
    user_telegram_id: Mapped[int] = mapped_column(BigInteger, nullable=False, index=True)
    
    # Текущий баланс баллов
    points_balance: Mapped[Decimal] = mapped_column(Numeric(10, 2), default=Decimal("0"))
    
    # Всего заработано баллов за всё время
    total_earned: Mapped[Decimal] = mapped_column(Numeric(10, 2), default=Decimal("0"))
    
    # Всего потрачено баллов за всё время
    total_spent: Mapped[Decimal] = mapped_column(Numeric(10, 2), default=Decimal("0"))
    
    created_at: Mapped[datetime] = mapped_column(default=datetime.utcnow)
    updated_at: Mapped[datetime] = mapped_column(default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationships
    business: Mapped["Business"] = relationship("Business", back_populates="loyalty_accounts")
    transactions: Mapped[list["LoyaltyTransaction"]] = relationship("LoyaltyTransaction", back_populates="account")


class LoyaltyTransaction(Base):
    """Модель транзакции программы лояльности."""

    __tablename__ = "loyalty_transactions"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    account_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("loyalty_accounts.id"), nullable=False, index=True)
    order_id: Mapped[uuid.UUID | None] = mapped_column(ForeignKey("orders.id"), nullable=True, index=True)
    
    # Тип транзакции: 'earned' (начислено) или 'spent' (потрачено)
    transaction_type: Mapped[str] = mapped_column(String(20), nullable=False)
    
    # Количество баллов (положительное для earned, отрицательное для spent)
    points: Mapped[Decimal] = mapped_column(Numeric(10, 2), nullable=False)
    
    # Баланс после транзакции
    balance_after: Mapped[Decimal] = mapped_column(Numeric(10, 2), nullable=False)
    
    # Описание транзакции
    description: Mapped[str | None] = mapped_column(Text, nullable=True)
    
    created_at: Mapped[datetime] = mapped_column(default=datetime.utcnow)

    # Relationships
    account: Mapped["LoyaltyAccount"] = relationship("LoyaltyAccount", back_populates="transactions")
    order: Mapped["Order"] = relationship("Order", back_populates="loyalty_transactions")

