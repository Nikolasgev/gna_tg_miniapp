"""Orders API."""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from pydantic import BaseModel
from typing import List
import uuid

from app.database import get_db

router = APIRouter()


class OrderItemRequest(BaseModel):
    """Элемент заказа в запросе."""

    product_id: uuid.UUID
    quantity: int
    note: str | None = None
    selected_variations: dict[str, str] | None = None  # Выбранные вариации {ключ: значение}


class CreateOrderRequest(BaseModel):
    """Запрос на создание заказа."""

    customer_name: str
    customer_phone: str
    customer_address: str | None = None
    items: List[OrderItemRequest]
    payment_method: str  # cash / online
    delivery_method: str = "pickup"  # pickup / delivery
    user_telegram_id: int | None = None  # ID пользователя Telegram
    promocode: str | None = None  # Промокод для применения
    loyalty_points_to_spend: float | None = None  # Количество баллов для списания


class PaymentResponse(BaseModel):
    """Ответ с информацией об оплате."""

    provider: str
    checkout_url: str | None = None


class CreateOrderResponse(BaseModel):
    """Ответ на создание заказа."""

    order_id: uuid.UUID
    payment: PaymentResponse | None = None


@router.post("/{business_slug}/orders", response_model=CreateOrderResponse)
async def create_order(
    business_slug: str,
    request: CreateOrderRequest,
    db: AsyncSession = Depends(get_db),
):
    """
    Создать заказ.

    Backend валидирует товары, перечитывает цены из БД и вычисляет итоговую сумму.
    """
    from app.services.order_service import OrderService
    from fastapi import HTTPException, status

    service = OrderService(db)

    try:
        # Преобразуем items в нужный формат
        items_data = [
            {
                "product_id": str(item.product_id),
                "quantity": item.quantity,
                "note": item.note,
            }
            for item in request.items
        ]

        from decimal import Decimal

        order = await service.create_order(
            business_slug=business_slug,
            customer_name=request.customer_name,
            customer_phone=request.customer_phone,
            customer_address=request.customer_address,
            items=items_data,
            payment_method=request.payment_method,
            delivery_method=request.delivery_method,
            user_telegram_id=request.user_telegram_id,
            promocode=request.promocode,
            loyalty_points_to_spend=Decimal(str(request.loyalty_points_to_spend)) if request.loyalty_points_to_spend else None,
        )

        # Если payment_method == "online", создаем платеж
        payment_response = None
        if request.payment_method == "online":
            from app.services.payment_service import PaymentService
            payment_service = PaymentService(db)
            
            # URL для возврата после оплаты (можно настроить в настройках бизнеса)
            return_url = f"https://t.me/your_bot?start=order_{order.id}"
            
            try:
                payment_info = await payment_service.create_yookassa_payment(
                    order=order,
                    return_url=return_url,
                )
                
                checkout_url = payment_info.get("confirmation", {}).get("confirmation_url")
                if checkout_url:
                    payment_response = PaymentResponse(
                        provider="yookassa",
                        checkout_url=checkout_url,
                    )
                else:
                    import logging
                    logger = logging.getLogger(__name__)
                    logger.error(f"YooKassa payment created but no checkout_url in response: {payment_info}")
            except Exception as e:
                # Если не удалось создать платеж, логируем ошибку
                import logging
                logger = logging.getLogger(__name__)
                logger.error(f"Failed to create YooKassa payment for order {order.id}: {e}", exc_info=True)
                # Возвращаем заказ без payment - пользователь может оплатить позже

        return CreateOrderResponse(
            order_id=order.id,
            payment=payment_response,
        )
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e),
        )


class OrderItemResponse(BaseModel):
    """Элемент заказа в ответе."""

    id: uuid.UUID
    product_id: uuid.UUID
    title_snapshot: str
    quantity: int
    unit_price: float
    total_price: float


class OrderResponse(BaseModel):
    """Ответ с информацией о заказе."""

    id: uuid.UUID
    customer_name: str
    customer_phone: str
    customer_address: str | None
    total_amount: float
    currency: str
    status: str
    payment_status: str
    payment_method: str
    created_at: str
    updated_at: str
    items: List[OrderItemResponse]


@router.get("/{business_slug}/orders", response_model=List[OrderResponse])
async def get_orders(
    business_slug: str,
    page: int = 1,
    limit: int = 20,
    db: AsyncSession = Depends(get_db),
):
    """
    Получить список заказов бизнеса (для админки).
    
    ⚠️ ВНИМАНИЕ: В production здесь должна быть проверка авторизации!
    """
    from app.services.order_service import OrderService
    from datetime import datetime

    service = OrderService(db)
    orders = await service.get_by_business_slug(
        business_slug=business_slug,
        page=page,
        limit=limit,
    )

    result = []
    for order in orders:
        result.append(
            OrderResponse(
                id=order.id,
                customer_name=order.customer_name,
                customer_phone=order.customer_phone,
                customer_address=order.customer_address,
                total_amount=float(order.total_amount),
                currency=order.currency,
                status=order.status,
                payment_status=order.payment_status,
                payment_method=order.payment_method,
                created_at=order.created_at.isoformat(),
                updated_at=order.updated_at.isoformat(),
                items=[
                    OrderItemResponse(
                        id=item.id,
                        product_id=item.product_id,
                        title_snapshot=item.title_snapshot,
                        quantity=item.quantity,
                        unit_price=float(item.unit_price),
                        total_price=float(item.total_price),
                    )
                    for item in order.items
                ],
            )
        )

    return result


@router.get("/orders/{order_id}", response_model=OrderResponse)
async def get_order(
    order_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
):
    """
    Получить заказ по ID.
    """
    from app.services.order_service import OrderService

    service = OrderService(db)
    order = await service.get_by_id(order_id)

    if not order:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Заказ с ID '{order_id}' не найден",
        )

    return OrderResponse(
        id=order.id,
        customer_name=order.customer_name,
        customer_phone=order.customer_phone,
        customer_address=order.customer_address,
        total_amount=float(order.total_amount),
        currency=order.currency,
        status=order.status,
        payment_status=order.payment_status,
        payment_method=order.payment_method,
        created_at=order.created_at.isoformat(),
        updated_at=order.updated_at.isoformat(),
        items=[
            OrderItemResponse(
                id=item.id,
                product_id=item.product_id,
                title_snapshot=item.title_snapshot,
                quantity=item.quantity,
                unit_price=float(item.unit_price),
                total_price=float(item.total_price),
            )
            for item in order.items
        ],
    )


@router.post("/orders/{order_id}/cancel", response_model=OrderResponse)
async def cancel_order(
    order_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
):
    """
    Отменить заказ.
    
    Заказ можно отменить только если его статус 'new' или 'accepted'.
    
    ⚠️ ВНИМАНИЕ: В production здесь должна быть проверка авторизации и права пользователя на отмену своего заказа!
    """
    from app.services.order_service import OrderService

    service = OrderService(db)
    
    try:
        order = await service.cancel_order(order_id)
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e),
        )

    if not order:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Заказ с ID '{order_id}' не найден",
        )

    return OrderResponse(
        id=order.id,
        customer_name=order.customer_name,
        customer_phone=order.customer_phone,
        customer_address=order.customer_address,
        total_amount=float(order.total_amount),
        currency=order.currency,
        status=order.status,
        payment_status=order.payment_status,
        payment_method=order.payment_method,
        created_at=order.created_at.isoformat(),
        updated_at=order.updated_at.isoformat(),
        items=[
            OrderItemResponse(
                id=item.id,
                product_id=item.product_id,
                title_snapshot=item.title_snapshot,
                quantity=item.quantity,
                unit_price=float(item.unit_price),
                total_price=float(item.total_price),
            )
            for item in order.items
        ],
    )


@router.get("/orders/user/{user_telegram_id}", response_model=List[OrderResponse])
async def get_user_orders(
    user_telegram_id: int,
    business_slug: str | None = None,
    page: int = 1,
    limit: int = 20,
    db: AsyncSession = Depends(get_db),
):
    """
    Получить заказы пользователя по Telegram ID.
    """
    from app.services.order_service import OrderService

    service = OrderService(db)
    orders = await service.get_by_user_telegram_id(
        user_telegram_id=user_telegram_id,
        business_slug=business_slug,
        page=page,
        limit=limit,
    )

    result = []
    for order in orders:
        result.append(
            OrderResponse(
                id=order.id,
                customer_name=order.customer_name,
                customer_phone=order.customer_phone,
                customer_address=order.customer_address,
                total_amount=float(order.total_amount),
                currency=order.currency,
                status=order.status,
                payment_status=order.payment_status,
                payment_method=order.payment_method,
                created_at=order.created_at.isoformat(),
                updated_at=order.updated_at.isoformat(),
                items=[
                    OrderItemResponse(
                        id=item.id,
                        product_id=item.product_id,
                        title_snapshot=item.title_snapshot,
                        quantity=item.quantity,
                        unit_price=float(item.unit_price),
                        total_price=float(item.total_price),
                    )
                    for item in order.items
                ],
            )
        )

    return result


class UpdateOrderStatusRequest(BaseModel):
    """Запрос на обновление статуса заказа."""

    status: str | None = None  # new, accepted, preparing, ready, cancelled, completed
    payment_status: str | None = None  # pending, paid, failed, refunded


@router.patch("/orders/{order_id}/status", response_model=OrderResponse)
async def update_order_status(
    order_id: uuid.UUID,
    request: UpdateOrderStatusRequest,
    db: AsyncSession = Depends(get_db),
):
    """
    Обновить статус заказа и/или статус оплаты.
    
    ⚠️ ВНИМАНИЕ: В production здесь должна быть проверка авторизации!
    """
    from app.services.order_service import OrderService

    if request.status is None and request.payment_status is None:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Необходимо указать хотя бы один статус для обновления",
        )

    service = OrderService(db)
    
    try:
        order = await service.update_status(
            order_id=order_id,
            status=request.status,
            payment_status=request.payment_status,
        )
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e),
        )

    if not order:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Заказ с ID '{order_id}' не найден",
        )

    return OrderResponse(
        id=order.id,
        customer_name=order.customer_name,
        customer_phone=order.customer_phone,
        customer_address=order.customer_address,
        total_amount=float(order.total_amount),
        currency=order.currency,
        status=order.status,
        payment_status=order.payment_status,
        payment_method=order.payment_method,
        created_at=order.created_at.isoformat(),
        updated_at=order.updated_at.isoformat(),
        items=[
            OrderItemResponse(
                id=item.id,
                product_id=item.product_id,
                title_snapshot=item.title_snapshot,
                quantity=item.quantity,
                unit_price=float(item.unit_price),
                total_price=float(item.total_price),
            )
            for item in order.items
        ],
    )


@router.post("/orders/{order_id}/cancel", response_model=OrderResponse)
async def cancel_order(
    order_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
):
    """
    Отменить заказ.
    
    Заказ можно отменить только если его статус 'new' или 'accepted'.
    
    ⚠️ ВНИМАНИЕ: В production здесь должна быть проверка авторизации и права пользователя на отмену своего заказа!
    """
    from app.services.order_service import OrderService

    service = OrderService(db)
    
    try:
        order = await service.cancel_order(order_id)
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e),
        )

    if not order:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Заказ с ID '{order_id}' не найден",
        )

    return OrderResponse(
        id=order.id,
        customer_name=order.customer_name,
        customer_phone=order.customer_phone,
        customer_address=order.customer_address,
        total_amount=float(order.total_amount),
        currency=order.currency,
        status=order.status,
        payment_status=order.payment_status,
        payment_method=order.payment_method,
        created_at=order.created_at.isoformat(),
        updated_at=order.updated_at.isoformat(),
        items=[
            OrderItemResponse(
                id=item.id,
                product_id=item.product_id,
                title_snapshot=item.title_snapshot,
                quantity=item.quantity,
                unit_price=float(item.unit_price),
                total_price=float(item.total_price),
            )
            for item in order.items
        ],
    )
