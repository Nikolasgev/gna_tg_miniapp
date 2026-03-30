"""Сервис для работы с настройками."""
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from uuid import UUID

from app.models.setting import Setting
from app.models.business import Business


class SettingService:
    """Сервис для работы с настройками."""

    def __init__(self, db: AsyncSession):
        self.db = db

    async def get_by_business_id(self, business_id: UUID) -> dict:
        """Получить все настройки бизнеса."""
        stmt = select(Setting).where(Setting.business_id == business_id)
        result = await self.db.execute(stmt)
        settings = result.scalars().all()

        # Преобразуем в словарь {key: value}
        # Если значение хранится как {"value": ...}, извлекаем value
        result_dict = {}
        for setting in settings:
            value = setting.value
            if isinstance(value, dict) and "value" in value and len(value) == 1:
                # Если это {"value": ...}, извлекаем value
                result_dict[setting.key] = value["value"]
            else:
                result_dict[setting.key] = value

        return result_dict

    async def get_by_key(self, business_id: UUID, key: str) -> dict | None:
        """Получить настройку по ключу."""
        stmt = select(Setting).where(
            Setting.business_id == business_id,
            Setting.key == key,
        )
        result = await self.db.execute(stmt)
        setting = result.scalar_one_or_none()

        return setting.value if setting else None

    async def set(self, business_id: UUID, key: str, value: dict) -> Setting:
        """Установить настройку."""
        # Проверяем, существует ли уже настройка
        stmt = select(Setting).where(
            Setting.business_id == business_id,
            Setting.key == key,
        )
        result = await self.db.execute(stmt)
        existing_setting = result.scalar_one_or_none()

        if existing_setting:
            # Обновляем существующую настройку
            existing_setting.value = value
            await self.db.commit()
            await self.db.refresh(existing_setting)
            return existing_setting
        else:
            # Создаем новую настройку
            setting = Setting(
                business_id=business_id,
                key=key,
                value=value,
            )
            self.db.add(setting)
            await self.db.commit()
            await self.db.refresh(setting)
            return setting

    async def get_value(self, business_id: UUID, key: str, default=None):
        """Получить значение настройки с дефолтным значением."""
        setting_value = await self.get_by_key(business_id, key)
        if setting_value is None:
            return default
        # Если значение хранится как {"value": ...}, извлекаем value
        if isinstance(setting_value, dict) and "value" in setting_value:
            return setting_value["value"]
        return setting_value

    async def delete(self, business_id: UUID, key: str) -> bool:
        """Удалить настройку."""
        from sqlalchemy import delete as sql_delete

        stmt = sql_delete(Setting).where(
            Setting.business_id == business_id,
            Setting.key == key,
        )
        result = await self.db.execute(stmt)
        await self.db.commit()
        return result.rowcount > 0

