"""Модель связи продукт-категория (M2M)."""
from sqlalchemy import ForeignKey, Table, Column

from app.database import Base

# Таблица для M2M связи
product_categories = Table(
    "product_categories",
    Base.metadata,
    Column("product_id", ForeignKey("products.id"), primary_key=True),
    Column("category_id", ForeignKey("categories.id"), primary_key=True),
)

