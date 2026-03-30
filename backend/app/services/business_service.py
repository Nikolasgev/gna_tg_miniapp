"""Сервис для работы с бизнесами."""
import uuid
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.business import Business


class BusinessService:
    """Сервис для работы с бизнесами."""

    def __init__(self, db: AsyncSession):
        self.db = db

    async def get_by_slug(self, slug: str) -> Business | None:
        """Получить бизнес по slug."""
        stmt = select(Business).where(Business.slug == slug)
        result = await self.db.execute(stmt)
        return result.scalar_one_or_none()

    async def create(self, owner_id: uuid.UUID, name: str, slug: str, description: str | None = None) -> Business:
        """Создать новый бизнес."""
        business = Business(
            owner_id=owner_id,
            name=name,
            slug=slug,
            description=description,
        )
        self.db.add(business)
        await self.db.commit()
        await self.db.refresh(business)
        return business

