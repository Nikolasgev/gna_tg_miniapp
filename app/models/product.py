"""Модель продукта."""
import uuid
from datetime import datetime
from decimal import Decimal

from sqlalchemy import String, Text, Numeric, Boolean, ForeignKey, JSON
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base
from app.models.product_category import product_categories


class Product(Base):
    """Модель продукта."""

    __tablename__ = "products"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    business_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("businesses.id"), nullable=False, index=True)
    title: Mapped[str] = mapped_column(String, nullable=False)
    description: Mapped[str | None] = mapped_column(Text, nullable=True)
    price: Mapped[Decimal] = mapped_column(Numeric(10, 2), nullable=False)
    currency: Mapped[str] = mapped_column(String(3), default="RUB")
    sku: Mapped[str | None] = mapped_column(String, nullable=True)
    image_url: Mapped[str | None] = mapped_column(String, nullable=True)
    variations: Mapped[dict | None] = mapped_column(JSON, nullable=True)  # Вариации товара (размер, цвет и т.д.)
    
    # Поля для скидок
    discount_percentage: Mapped[Decimal | None] = mapped_column(Numeric(5, 2), nullable=True)  # Процент скидки (0-100)
    discount_price: Mapped[Decimal | None] = mapped_column(Numeric(10, 2), nullable=True)  # Цена со скидкой
    discount_valid_from: Mapped[datetime | None] = mapped_column(nullable=True)  # Дата начала действия скидки
    discount_valid_until: Mapped[datetime | None] = mapped_column(nullable=True)  # Дата окончания действия скидки
    
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    created_at: Mapped[datetime] = mapped_column(default=datetime.utcnow)
    updated_at: Mapped[datetime] = mapped_column(default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationships
    business: Mapped["Business"] = relationship("Business", back_populates="products")
    order_items: Mapped[list["OrderItem"]] = relationship("OrderItem", back_populates="product")
    categories: Mapped[list["Category"]] = relationship(
        "Category", secondary=product_categories, back_populates="products"
    )

