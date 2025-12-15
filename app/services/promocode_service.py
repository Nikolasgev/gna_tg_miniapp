"""Сервис для работы с промокодами."""
from datetime import datetime
from decimal import Decimal
from uuid import UUID
from sqlalchemy import select, func, and_
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.models.promocode import Promocode, PromocodeUsage
from app.models.order import Order


class PromocodeService:
    """Сервис для работы с промокодами."""

    def __init__(self, db: AsyncSession):
        self.db = db

    async def validate_promocode(
        self,
        code: str,
        business_id: UUID,
        order_amount: Decimal,
        user_telegram_id: int | None = None,
    ) -> tuple[Promocode | None, str]:
        """
        Проверить промокод и вернуть его, если он валиден.
        
        Returns:
            Tuple (promocode, error_message)
            Если промокод валиден - возвращает (promocode, "")
            Если невалиден - возвращает (None, "описание ошибки")
        """
        # Находим промокод
        stmt = select(Promocode).where(
            Promocode.code == code.upper().strip(),
            Promocode.business_id == business_id,
        )
        result = await self.db.execute(stmt)
        promocode = result.scalar_one_or_none()

        if not promocode:
            return None, "Промокод не найден"

        if not promocode.is_active:
            return None, "Промокод неактивен"

        # Проверяем даты действия
        now = datetime.utcnow()
        if promocode.valid_from and now < promocode.valid_from:
            return None, f"Промокод будет действителен с {promocode.valid_from.strftime('%d.%m.%Y')}"
        
        if promocode.valid_until and now > promocode.valid_until:
            return None, "Промокод истёк"

        # Проверяем минимальную сумму заказа
        if promocode.min_order_amount and order_amount < promocode.min_order_amount:
            return None, f"Минимальная сумма заказа для этого промокода: {promocode.min_order_amount}"

        # Проверяем максимальное количество использований
        if promocode.max_uses is not None and promocode.uses_count >= promocode.max_uses:
            return None, "Промокод исчерпан"

        # Проверяем лимит использований на пользователя
        if user_telegram_id is not None and promocode.max_uses_per_user is not None:
            # Важно: делаем flush, чтобы увидеть незакоммиченные записи в текущей транзакции
            await self.db.flush()
            
            stmt_usage = select(func.count(PromocodeUsage.id)).where(
                and_(
                    PromocodeUsage.promocode_id == promocode.id,
                    PromocodeUsage.user_telegram_id == user_telegram_id,
                )
            )
            result_usage = await self.db.execute(stmt_usage)
            user_usage_count = result_usage.scalar() or 0
            
            # Логируем для отладки
            import logging
            logger = logging.getLogger(__name__)
            logger.info(
                f"Checking promocode usage limit: promocode_id={promocode.id}, "
                f"user_telegram_id={user_telegram_id}, "
                f"max_uses_per_user={promocode.max_uses_per_user}, "
                f"current_usage_count={user_usage_count}"
            )

            if user_usage_count >= promocode.max_uses_per_user:
                return None, "Вы уже использовали этот промокод максимальное количество раз"
        elif user_telegram_id is None and promocode.max_uses_per_user is not None:
            # Если промокод имеет ограничение на пользователя, но user_telegram_id не передан,
            # мы не можем проверить лимит, поэтому отклоняем промокод
            return None, "Для использования этого промокода требуется авторизация"

        return promocode, ""

    async def calculate_discount(
        self,
        promocode: Promocode,
        order_amount: Decimal,
    ) -> Decimal:
        """
        Рассчитать размер скидки по промокоду.
        
        Returns:
            Размер скидки в валюте заказа
        """
        if promocode.discount_type == "percentage":
            # Процентная скидка
            discount = order_amount * (promocode.discount_value / Decimal("100"))
            
            # Применяем максимальную сумму скидки, если указана
            if promocode.max_discount_amount:
                discount = min(discount, promocode.max_discount_amount)
        else:
            # Фиксированная скидка
            discount = promocode.discount_value

        # Скидка не может быть больше суммы заказа
        discount = min(discount, order_amount)

        return discount.quantize(Decimal("0.01"))

    async def apply_promocode(
        self,
        promocode: Promocode,
        order: Order,
        discount_amount: Decimal,
        order_amount_before: Decimal,
        order_amount_after: Decimal,
    ) -> PromocodeUsage:
        """
        Применить промокод к заказу.
        
        Создаёт запись об использовании промокода и увеличивает счётчик использований.
        """
        # Создаём запись об использовании
        usage = PromocodeUsage(
            promocode_id=promocode.id,
            order_id=order.id,
            user_telegram_id=order.user_telegram_id,
            discount_amount=discount_amount,
            order_amount_before=order_amount_before,
            order_amount_after=order_amount_after,
        )
        self.db.add(usage)

        # Увеличиваем счётчик использований
        promocode.uses_count += 1

        await self.db.flush()
        return usage

    async def get_by_business(
        self,
        business_id: UUID,
        is_active: bool | None = None,
    ) -> list[Promocode]:
        """Получить список промокодов бизнеса."""
        stmt = select(Promocode).where(Promocode.business_id == business_id)

        if is_active is not None:
            stmt = stmt.where(Promocode.is_active == is_active)

        stmt = stmt.order_by(Promocode.created_at.desc())

        result = await self.db.execute(stmt)
        return list(result.scalars().all())

    async def get_by_id(self, promocode_id: UUID) -> Promocode | None:
        """Получить промокод по ID."""
        stmt = select(Promocode).where(Promocode.id == promocode_id)
        result = await self.db.execute(stmt)
        return result.scalar_one_or_none()

    async def create_promocode(
        self,
        business_id: UUID,
        code: str,
        discount_type: str,
        discount_value: Decimal,
        description: str | None = None,
        min_order_amount: Decimal | None = None,
        max_discount_amount: Decimal | None = None,
        max_uses: int | None = None,
        max_uses_per_user: int | None = 1,
        valid_from: datetime | None = None,
        valid_until: datetime | None = None,
        is_active: bool = True,
    ) -> Promocode:
        """Создать новый промокод."""
        # Проверяем, что код уникален
        stmt = select(Promocode).where(Promocode.code == code.upper().strip())
        result = await self.db.execute(stmt)
        existing = result.scalar_one_or_none()
        
        if existing:
            raise ValueError(f"Промокод с кодом '{code}' уже существует")

        promocode = Promocode(
            business_id=business_id,
            code=code.upper().strip(),
            description=description,
            discount_type=discount_type,
            discount_value=discount_value,
            min_order_amount=min_order_amount,
            max_discount_amount=max_discount_amount,
            max_uses=max_uses,
            max_uses_per_user=max_uses_per_user,
            valid_from=valid_from,
            valid_until=valid_until,
            is_active=is_active,
        )

        self.db.add(promocode)
        await self.db.flush()
        await self.db.refresh(promocode)
        
        return promocode

    async def update_promocode(
        self,
        promocode_id: UUID,
        **kwargs,
    ) -> Promocode | None:
        """Обновить промокод."""
        promocode = await self.get_by_id(promocode_id)
        if not promocode:
            return None

        # Обновляем поля, если они переданы
        for key, value in kwargs.items():
            if hasattr(promocode, key) and value is not None:
                setattr(promocode, key, value)

        await self.db.commit()
        await self.db.refresh(promocode)
        
        return promocode

    async def delete_promocode(self, promocode_id: UUID) -> bool:
        """Удалить промокод."""
        promocode = await self.get_by_id(promocode_id)
        if not promocode:
            return False

        await self.db.delete(promocode)
        await self.db.commit()
        
        return True

