"""Loyalty program API."""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from pydantic import BaseModel
from typing import List
from decimal import Decimal
import uuid

from app.database import get_db
from app.services.loyalty_service import LoyaltyService

router = APIRouter()


class LoyaltyAccountResponse(BaseModel):
    """Ответ с информацией о счёте программы лояльности."""

    id: uuid.UUID
    business_id: uuid.UUID
    user_telegram_id: int
    points_balance: float
    total_earned: float
    total_spent: float


class LoyaltyTransactionResponse(BaseModel):
    """Ответ с информацией о транзакции программы лояльности."""

    id: uuid.UUID
    order_id: uuid.UUID | None
    transaction_type: str  # "earned" или "spent"
    points: float
    balance_after: float
    description: str | None
    created_at: str


class LoyaltyAccountDetailResponse(BaseModel):
    """Детальный ответ с информацией о счёте и транзакциях."""

    account: LoyaltyAccountResponse
    transactions: List[LoyaltyTransactionResponse]


@router.get("/businesses/{business_id}/loyalty/account/{user_telegram_id}", response_model=LoyaltyAccountResponse)
async def get_loyalty_account(
    business_id: uuid.UUID,
    user_telegram_id: int,
    db: AsyncSession = Depends(get_db),
):
    """Получить счёт программы лояльности пользователя."""
    service = LoyaltyService(db)
    
    account = await service.get_account(
        business_id=business_id,
        user_telegram_id=user_telegram_id,
    )

    if not account:
        # Создаём пустой счёт, если его нет
        account = await service.get_or_create_account(
            business_id=business_id,
            user_telegram_id=user_telegram_id,
        )
        await db.commit()

    return LoyaltyAccountResponse(
        id=account.id,
        business_id=account.business_id,
        user_telegram_id=account.user_telegram_id,
        points_balance=float(account.points_balance),
        total_earned=float(account.total_earned),
        total_spent=float(account.total_spent),
    )


@router.get("/businesses/{business_id}/loyalty/account/{user_telegram_id}/detail", response_model=LoyaltyAccountDetailResponse)
async def get_loyalty_account_detail(
    business_id: uuid.UUID,
    user_telegram_id: int,
    limit: int = 50,
    offset: int = 0,
    db: AsyncSession = Depends(get_db),
):
    """Получить детальную информацию о счёте программы лояльности с историей транзакций."""
    service = LoyaltyService(db)
    
    account = await service.get_user_account(
        business_id=business_id,
        user_telegram_id=user_telegram_id,
    )

    if not account:
        # Создаём пустой счёт, если его нет
        account = await service.get_or_create_account(
            business_id=business_id,
            user_telegram_id=user_telegram_id,
        )
        await db.commit()

    transactions = await service.get_account_transactions(
        account_id=account.id,
        limit=limit,
        offset=offset,
    )

    return LoyaltyAccountDetailResponse(
        account=LoyaltyAccountResponse(
            id=account.id,
            business_id=account.business_id,
            user_telegram_id=account.user_telegram_id,
            points_balance=float(account.points_balance),
            total_earned=float(account.total_earned),
            total_spent=float(account.total_spent),
        ),
        transactions=[
            LoyaltyTransactionResponse(
                id=t.id,
                order_id=t.order_id,
                transaction_type=t.transaction_type,
                points=float(t.points),
                balance_after=float(t.balance_after),
                description=t.description,
                created_at=t.created_at.isoformat(),
            )
            for t in transactions
        ],
    )


@router.get("/businesses/{business_slug}/loyalty/account", response_model=LoyaltyAccountResponse)
async def get_loyalty_account_by_slug(
    business_slug: str,
    user_telegram_id: int,
    db: AsyncSession = Depends(get_db),
):
    """
    Получить счёт программы лояльности пользователя по slug бизнеса.
    
    Удобно для использования из Mini App, где известен slug, а не ID.
    """
    from app.models.business import Business
    from sqlalchemy import select

    # Находим бизнес по slug
    stmt = select(Business).where(Business.slug == business_slug)
    result = await db.execute(stmt)
    business = result.scalar_one_or_none()

    if not business:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Бизнес с slug '{business_slug}' не найден",
        )

    service = LoyaltyService(db)
    
    account = await service.get_or_create_account(
        business_id=business.id,
        user_telegram_id=user_telegram_id,
    )
    
    await db.commit()

    return LoyaltyAccountResponse(
        id=account.id,
        business_id=account.business_id,
        user_telegram_id=account.user_telegram_id,
        points_balance=float(account.points_balance),
        total_earned=float(account.total_earned),
        total_spent=float(account.total_spent),
    )

