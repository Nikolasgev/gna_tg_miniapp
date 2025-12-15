"""Сервис для работы с администраторами."""
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import verify_password, get_password_hash
from app.models.setting import Setting
from app.config import settings


class AdminService:
    """Сервис для работы с администраторами."""

    def __init__(self, db: AsyncSession):
        self.db = db

    async def verify_password(self, password: str) -> bool:
        """
        Проверка пароля администратора.

        Пароль хранится в таблице settings с ключом 'admin_password'.
        Если записи нет, создается с паролем из переменной окружения.
        """
        # Ищем пароль в БД (без привязки к бизнесу)
        stmt = select(Setting).where(
            Setting.key == "admin_password",
            Setting.business_id.is_(None),
        )
        result = await self.db.execute(stmt)
        setting = result.scalar_one_or_none()

        if setting is None:
            # Если записи нет, создаем с паролем из env
            # settings.admin_password уже строка
            hashed_password = get_password_hash(settings.admin_password)
            setting = Setting(
                key="admin_password",
                business_id=None,
                value={"hashed_password": hashed_password},
            )
            self.db.add(setting)
            await self.db.commit()
            await self.db.refresh(setting)

        # Получаем хешированный пароль
        hashed_password = setting.value.get("hashed_password")
        if not hashed_password:
            return False

        # Проверяем пароль
        return verify_password(password, hashed_password)

    async def set_password(self, new_password: str) -> None:
        """Установка нового пароля администратора."""
        hashed_password = get_password_hash(new_password)

        stmt = select(Setting).where(Setting.key == "admin_password")
        result = await self.db.execute(stmt)
        setting = result.scalar_one_or_none()

        if setting:
            setting.value = {"hashed_password": hashed_password}
        else:
            setting = Setting(
                key="admin_password",
                business_id=None,
                value={"hashed_password": hashed_password},
            )
            self.db.add(setting)

        await self.db.commit()

