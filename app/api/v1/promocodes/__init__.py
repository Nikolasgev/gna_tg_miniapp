"""Promocodes API."""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from pydantic import BaseModel
from typing import List
from datetime import datetime
from decimal import Decimal
import uuid

from app.database import get_db
from app.services.promocode_service import PromocodeService

router = APIRouter()


class PromocodeCreateRequest(BaseModel):
    """Запрос на создание промокода."""

    code: str
    description: str | None = None
    discount_type: str  # "percentage" или "fixed"
    discount_value: Decimal
    min_order_amount: Decimal | None = None
    max_discount_amount: Decimal | None = None
    max_uses: int | None = None
    max_uses_per_user: int | None = 1
    valid_from: datetime | None = None
    valid_until: datetime | None = None
    is_active: bool = True


class PromocodeUpdateRequest(BaseModel):
    """Запрос на обновление промокода."""

    description: str | None = None
    discount_type: str | None = None
    discount_value: Decimal | None = None
    min_order_amount: Decimal | None = None
    max_discount_amount: Decimal | None = None
    max_uses: int | None = None
    max_uses_per_user: int | None = None
    valid_from: datetime | None = None
    valid_until: datetime | None = None
    is_active: bool | None = None


class PromocodeValidateRequest(BaseModel):
    """Запрос на валидацию промокода."""

    code: str
    order_amount: Decimal
    user_telegram_id: int | None = None


class PromocodeResponse(BaseModel):
    """Ответ с информацией о промокоде."""

    id: uuid.UUID
    code: str
    description: str | None
    discount_type: str
    discount_value: float
    min_order_amount: float | None
    max_discount_amount: float | None
    max_uses: int | None
    uses_count: int
    max_uses_per_user: int | None
    valid_from: str | None
    valid_until: str | None
    is_active: bool
    created_at: str
    updated_at: str


class PromocodeValidateResponse(BaseModel):
    """Ответ на валидацию промокода."""

    valid: bool
    discount_amount: float | None = None
    error: str | None = None
    promocode: PromocodeResponse | None = None


@router.post("/businesses/{business_id}/promocodes/validate", response_model=PromocodeValidateResponse)
async def validate_promocode(
    business_id: uuid.UUID,
    request: PromocodeValidateRequest,
    db: AsyncSession = Depends(get_db),
):
    """
    Проверить и применить промокод.
    
    Возвращает информацию о промокоде и размер скидки, которую он даёт.
    """
    service = PromocodeService(db)

    try:
        # Логируем входные данные для отладки
        import logging
        logger = logging.getLogger(__name__)
        logger.info(
            f"Validating promocode: code={request.code}, "
            f"business_id={business_id}, "
            f"order_amount={request.order_amount}, "
            f"user_telegram_id={request.user_telegram_id}"
        )
        
        promocode, error = await service.validate_promocode(
            code=request.code,
            business_id=business_id,
            order_amount=request.order_amount,
            user_telegram_id=request.user_telegram_id,
        )

        if error:
            logger.warning(f"Promocode validation failed: {error}")
            return PromocodeValidateResponse(
                valid=False,
                error=error,
            )

        discount_amount = await service.calculate_discount(
            promocode=promocode,
            order_amount=request.order_amount,
        )

        return PromocodeValidateResponse(
            valid=True,
            discount_amount=float(discount_amount),
            promocode=PromocodeResponse(
                id=promocode.id,
                code=promocode.code,
                description=promocode.description,
                discount_type=promocode.discount_type,
                discount_value=float(promocode.discount_value),
                min_order_amount=float(promocode.min_order_amount) if promocode.min_order_amount else None,
                max_discount_amount=float(promocode.max_discount_amount) if promocode.max_discount_amount else None,
                max_uses=promocode.max_uses,
                uses_count=promocode.uses_count,
                max_uses_per_user=promocode.max_uses_per_user,
                valid_from=promocode.valid_from.isoformat() if promocode.valid_from else None,
                valid_until=promocode.valid_until.isoformat() if promocode.valid_until else None,
                is_active=promocode.is_active,
                created_at=promocode.created_at.isoformat(),
                updated_at=promocode.updated_at.isoformat(),
            ),
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Ошибка при проверке промокода: {str(e)}",
        )


@router.post("/businesses/{business_id}/promocodes", response_model=PromocodeResponse)
async def create_promocode(
    business_id: uuid.UUID,
    request: PromocodeCreateRequest,
    db: AsyncSession = Depends(get_db),
):
    """
    Создать новый промокод.
    
    ⚠️ ВНИМАНИЕ: В production здесь должна быть проверка авторизации!
    """
    service = PromocodeService(db)

    try:
        promocode = await service.create_promocode(
            business_id=business_id,
            code=request.code,
            discount_type=request.discount_type,
            discount_value=request.discount_value,
            description=request.description,
            min_order_amount=request.min_order_amount,
            max_discount_amount=request.max_discount_amount,
            max_uses=request.max_uses,
            max_uses_per_user=request.max_uses_per_user,
            valid_from=request.valid_from,
            valid_until=request.valid_until,
            is_active=request.is_active,
        )

        await db.commit()

        return PromocodeResponse(
            id=promocode.id,
            code=promocode.code,
            description=promocode.description,
            discount_type=promocode.discount_type,
            discount_value=float(promocode.discount_value),
            min_order_amount=float(promocode.min_order_amount) if promocode.min_order_amount else None,
            max_discount_amount=float(promocode.max_discount_amount) if promocode.max_discount_amount else None,
            max_uses=promocode.max_uses,
            uses_count=promocode.uses_count,
            max_uses_per_user=promocode.max_uses_per_user,
            valid_from=promocode.valid_from.isoformat() if promocode.valid_from else None,
            valid_until=promocode.valid_until.isoformat() if promocode.valid_until else None,
            is_active=promocode.is_active,
            created_at=promocode.created_at.isoformat(),
            updated_at=promocode.updated_at.isoformat(),
        )
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e),
        )


@router.get("/businesses/{business_id}/promocodes", response_model=List[PromocodeResponse])
async def get_promocodes(
    business_id: uuid.UUID,
    is_active: bool | None = None,
    db: AsyncSession = Depends(get_db),
):
    """
    Получить список промокодов бизнеса.
    
    ⚠️ ВНИМАНИЕ: В production здесь должна быть проверка авторизации!
    """
    service = PromocodeService(db)
    promocodes = await service.get_by_business(
        business_id=business_id,
        is_active=is_active,
    )

    return [
        PromocodeResponse(
            id=pc.id,
            code=pc.code,
            description=pc.description,
            discount_type=pc.discount_type,
            discount_value=float(pc.discount_value),
            min_order_amount=float(pc.min_order_amount) if pc.min_order_amount else None,
            max_discount_amount=float(pc.max_discount_amount) if pc.max_discount_amount else None,
            max_uses=pc.max_uses,
            uses_count=pc.uses_count,
            max_uses_per_user=pc.max_uses_per_user,
            valid_from=pc.valid_from.isoformat() if pc.valid_from else None,
            valid_until=pc.valid_until.isoformat() if pc.valid_until else None,
            is_active=pc.is_active,
            created_at=pc.created_at.isoformat(),
            updated_at=pc.updated_at.isoformat(),
        )
        for pc in promocodes
    ]


@router.get("/promocodes/{promocode_id}", response_model=PromocodeResponse)
async def get_promocode(
    promocode_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
):
    """Получить промокод по ID."""
    service = PromocodeService(db)
    promocode = await service.get_by_id(promocode_id)

    if not promocode:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Промокод с ID '{promocode_id}' не найден",
        )

    return PromocodeResponse(
        id=promocode.id,
        code=promocode.code,
        description=promocode.description,
        discount_type=promocode.discount_type,
        discount_value=float(promocode.discount_value),
        min_order_amount=float(promocode.min_order_amount) if promocode.min_order_amount else None,
        max_discount_amount=float(promocode.max_discount_amount) if promocode.max_discount_amount else None,
        max_uses=promocode.max_uses,
        uses_count=promocode.uses_count,
        max_uses_per_user=promocode.max_uses_per_user,
        valid_from=promocode.valid_from.isoformat() if promocode.valid_from else None,
        valid_until=promocode.valid_until.isoformat() if promocode.valid_until else None,
        is_active=promocode.is_active,
        created_at=promocode.created_at.isoformat(),
        updated_at=promocode.updated_at.isoformat(),
    )


@router.put("/promocodes/{promocode_id}", response_model=PromocodeResponse)
async def update_promocode(
    promocode_id: uuid.UUID,
    request: PromocodeUpdateRequest,
    db: AsyncSession = Depends(get_db),
):
    """
    Обновить промокод.
    
    ⚠️ ВНИМАНИЕ: В production здесь должна быть проверка авторизации!
    """
    service = PromocodeService(db)
    
    update_data = {}
    if request.description is not None:
        update_data["description"] = request.description
    if request.discount_type is not None:
        update_data["discount_type"] = request.discount_type
    if request.discount_value is not None:
        update_data["discount_value"] = request.discount_value
    if request.min_order_amount is not None:
        update_data["min_order_amount"] = request.min_order_amount
    if request.max_discount_amount is not None:
        update_data["max_discount_amount"] = request.max_discount_amount
    if request.max_uses is not None:
        update_data["max_uses"] = request.max_uses
    if request.max_uses_per_user is not None:
        update_data["max_uses_per_user"] = request.max_uses_per_user
    if request.valid_from is not None:
        update_data["valid_from"] = request.valid_from
    if request.valid_until is not None:
        update_data["valid_until"] = request.valid_until
    if request.is_active is not None:
        update_data["is_active"] = request.is_active

    promocode = await service.update_promocode(
        promocode_id=promocode_id,
        **update_data,
    )

    if not promocode:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Промокод с ID '{promocode_id}' не найден",
        )

    return PromocodeResponse(
        id=promocode.id,
        code=promocode.code,
        description=promocode.description,
        discount_type=promocode.discount_type,
        discount_value=float(promocode.discount_value),
        min_order_amount=float(promocode.min_order_amount) if promocode.min_order_amount else None,
        max_discount_amount=float(promocode.max_discount_amount) if promocode.max_discount_amount else None,
        max_uses=promocode.max_uses,
        uses_count=promocode.uses_count,
        max_uses_per_user=promocode.max_uses_per_user,
        valid_from=promocode.valid_from.isoformat() if promocode.valid_from else None,
        valid_until=promocode.valid_until.isoformat() if promocode.valid_until else None,
        is_active=promocode.is_active,
        created_at=promocode.created_at.isoformat(),
        updated_at=promocode.updated_at.isoformat(),
    )


@router.delete("/promocodes/{promocode_id}")
async def delete_promocode(
    promocode_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
):
    """
    Удалить промокод.
    
    ⚠️ ВНИМАНИЕ: В production здесь должна быть проверка авторизации!
    """
    service = PromocodeService(db)
    deleted = await service.delete_promocode(promocode_id)

    if not deleted:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Промокод с ID '{promocode_id}' не найден",
        )

    return {"message": "Промокод удалён"}

