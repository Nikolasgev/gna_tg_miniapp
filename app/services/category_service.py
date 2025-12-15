"""Сервис для работы с категориями."""
from decimal import Decimal
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from uuid import UUID

from app.models.category import Category
from app.models.business import Business


class CategoryService:
    """Сервис для работы с категориями."""

    def __init__(self, db: AsyncSession):
        self.db = db

    async def get_by_business_slug(self, business_slug: str) -> list[Category]:
        """Получить все категории бизнеса."""
        # Находим бизнес
        stmt_business = select(Business).where(Business.slug == business_slug)
        result = await self.db.execute(stmt_business)
        business = result.scalar_one_or_none()

        if not business:
            return []

        # Получаем категории
        stmt = select(Category).where(
            Category.business_id == business.id
        ).order_by(Category.position, Category.name)

        result = await self.db.execute(stmt)
        return list(result.scalars().all())

    async def get_by_id(self, category_id: UUID) -> Category | None:
        """Получить категорию по ID."""
        stmt = select(Category).where(Category.id == category_id)
        result = await self.db.execute(stmt)
        return result.scalar_one_or_none()

    async def create(
        self,
        business_id: UUID,
        name: str,
        position: int = 0,
        surcharge: Decimal | None = None,
    ) -> Category:
        """Создать новую категорию."""
        category = Category(
            business_id=business_id,
            name=name,
            position=position,
            surcharge=surcharge if surcharge is not None else Decimal('0.00'),
        )
        self.db.add(category)
        await self.db.commit()
        await self.db.refresh(category)
        return category

    async def update(
        self,
        category_id: UUID,
        name: str | None = None,
        position: int | None = None,
        surcharge: Decimal | None = None,
    ) -> Category | None:
        """Обновить категорию."""
        category = await self.get_by_id(category_id)
        if not category:
            return None

        if name is not None:
            category.name = name
        if position is not None:
            category.position = position
        if surcharge is not None:
            category.surcharge = surcharge

        await self.db.commit()
        await self.db.refresh(category)
        return category

    async def delete(self, category_id: UUID) -> bool:
        """Удалить категорию."""
        category = await self.get_by_id(category_id)
        if not category:
            return False

        # Удаляем связи с продуктами
        from app.models.product_category import product_categories
        from sqlalchemy import delete as sql_delete
        stmt_delete_categories = sql_delete(product_categories).where(
            product_categories.c.category_id == category_id
        )
        await self.db.execute(stmt_delete_categories)

        # Удаляем саму категорию
        stmt_delete_category = sql_delete(Category).where(Category.id == category_id)
        result = await self.db.execute(stmt_delete_category)
        await self.db.commit()
        return result.rowcount > 0

