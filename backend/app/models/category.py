"""Модель категории."""
import uuid
from datetime import datetime
from decimal import Decimal

from sqlalchemy import String, Integer, ForeignKey, Numeric
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base
from app.models.product_category import product_categories


class Category(Base):
    """Модель категории."""

    __tablename__ = "categories"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    business_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("businesses.id"), nullable=False, index=True)
    name: Mapped[str] = mapped_column(String, nullable=False)
    position: Mapped[int] = mapped_column(Integer, default=0)
    surcharge: Mapped[Decimal] = mapped_column(Numeric(10, 2), default=Decimal('0.00'))  # Доплата за категорию
    created_at: Mapped[datetime] = mapped_column(default=datetime.utcnow)
    updated_at: Mapped[datetime] = mapped_column(default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationships
    products: Mapped[list["Product"]] = relationship(
        "Product", secondary=product_categories, back_populates="categories"
    )

