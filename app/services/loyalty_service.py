"""Сервис для работы с программой лояльности."""
from decimal import Decimal
from uuid import UUID
from sqlalchemy import select, and_
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.models.loyalty import LoyaltyAccount, LoyaltyTransaction
from app.models.order import Order


class LoyaltyService:
    """Сервис для работы с программой лояльности."""

    def __init__(self, db: AsyncSession):
        self.db = db

    async def get_or_create_account(
        self,
        business_id: UUID,
        user_telegram_id: int,
    ) -> LoyaltyAccount:
        """Получить или создать счёт программы лояльности для пользователя."""
        stmt = select(LoyaltyAccount).where(
            and_(
                LoyaltyAccount.business_id == business_id,
                LoyaltyAccount.user_telegram_id == user_telegram_id,
            )
        )
        result = await self.db.execute(stmt)
        account = result.scalar_one_or_none()

        if not account:
            account = LoyaltyAccount(
                business_id=business_id,
                user_telegram_id=user_telegram_id,
                points_balance=Decimal("0"),
                total_earned=Decimal("0"),
                total_spent=Decimal("0"),
            )
            self.db.add(account)
            await self.db.flush()
            await self.db.refresh(account)

        return account

    async def get_account(
        self,
        business_id: UUID,
        user_telegram_id: int,
    ) -> LoyaltyAccount | None:
        """Получить счёт программы лояльности пользователя."""
        stmt = select(LoyaltyAccount).where(
            and_(
                LoyaltyAccount.business_id == business_id,
                LoyaltyAccount.user_telegram_id == user_telegram_id,
            )
        )
        result = await self.db.execute(stmt)
        return result.scalar_one_or_none()

    async def calculate_points_earned(
        self,
        order_amount: Decimal,
        percent: Decimal = Decimal("1.00"),  # По умолчанию 1% от суммы
    ) -> Decimal:
        """
        Рассчитать количество баллов, которые будут начислены за заказ.
        
        Args:
            order_amount: Сумма заказа
            percent: Процент начисления баллов от суммы заказа (по умолчанию 1.0 = 1%)
        
        Returns:
            Количество баллов для начисления
        """
        # Процент от суммы: 1% = 1.0, значит points = order_amount * (percent / 100)
        points = order_amount * (percent / Decimal("100"))
        return points.quantize(Decimal("0.01"))

    async def earn_points(
        self,
        account: LoyaltyAccount,
        points: Decimal,
        order: Order | None = None,
        description: str | None = None,
    ) -> LoyaltyTransaction:
        """
        Начислить баллы на счёт пользователя.
        
        Args:
            account: Счёт программы лояльности
            points: Количество баллов для начисления
            order: Заказ, за который начисляются баллы (опционально)
            description: Описание транзакции (опционально)
        
        Returns:
            Созданная транзакция
        """
        if points <= 0:
            raise ValueError("Количество баллов должно быть положительным")

        # Обновляем баланс и статистику
        account.points_balance += points
        account.total_earned += points

        # Создаём транзакцию
        transaction = LoyaltyTransaction(
            account_id=account.id,
            order_id=order.id if order else None,
            transaction_type="earned",
            points=points,
            balance_after=account.points_balance,
            description=description or f"Начислено за заказ #{order.id if order else 'N/A'}",
        )
        self.db.add(transaction)
        await self.db.flush()

        return transaction

    async def spend_points(
        self,
        account: LoyaltyAccount,
        points: Decimal,
        order: Order | None = None,
        description: str | None = None,
    ) -> LoyaltyTransaction:
        """
        Списать баллы со счёта пользователя.
        
        Args:
            account: Счёт программы лояльности
            points: Количество баллов для списания
            order: Заказ, за который списываются баллы (опционально)
            description: Описание транзакции (опционально)
        
        Returns:
            Созданная транзакция
        """
        if points <= 0:
            raise ValueError("Количество баллов должно быть положительным")

        if account.points_balance < points:
            raise ValueError(
                f"Недостаточно баллов. Доступно: {account.points_balance}, требуется: {points}"
            )

        # Обновляем баланс и статистику
        account.points_balance -= points
        account.total_spent += points

        # Создаём транзакцию
        transaction = LoyaltyTransaction(
            account_id=account.id,
            order_id=order.id if order else None,
            transaction_type="spent",
            points=-points,  # Отрицательное значение для списания
            balance_after=account.points_balance,
            description=description or f"Списано за заказ #{order.id if order else 'N/A'}",
        )
        self.db.add(transaction)
        await self.db.flush()

        return transaction

    async def calculate_discount_from_points(
        self,
        points: Decimal,
        points_per_rub: Decimal = Decimal("1"),  # По умолчанию 1 балл = 1 рубль скидки
    ) -> Decimal:
        """
        Рассчитать размер скидки, которую можно получить за баллы.
        
        Args:
            points: Количество баллов
            points_per_rub: Количество баллов за 1 рубль скидки (по умолчанию 1)
        
        Returns:
            Размер скидки в рублях
        """
        discount = points / points_per_rub
        return discount.quantize(Decimal("0.01"))

    async def get_account_transactions(
        self,
        account_id: UUID,
        limit: int = 50,
        offset: int = 0,
    ) -> list[LoyaltyTransaction]:
        """Получить историю транзакций по счёту."""
        stmt = (
            select(LoyaltyTransaction)
            .where(LoyaltyTransaction.account_id == account_id)
            .order_by(LoyaltyTransaction.created_at.desc())
            .limit(limit)
            .offset(offset)
        )
        result = await self.db.execute(stmt)
        return list(result.scalars().all())

    async def get_user_account(
        self,
        business_id: UUID,
        user_telegram_id: int,
    ) -> LoyaltyAccount | None:
        """Получить счёт пользователя с транзакциями."""
        stmt = (
            select(LoyaltyAccount)
            .options(selectinload(LoyaltyAccount.transactions))
            .where(
                and_(
                    LoyaltyAccount.business_id == business_id,
                    LoyaltyAccount.user_telegram_id == user_telegram_id,
                )
            )
        )
        result = await self.db.execute(stmt)
        return result.scalar_one_or_none()

