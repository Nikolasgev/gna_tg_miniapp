"""Orders API."""
from fastapi import APIRouter, Depends, Header, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from pydantic import BaseModel
from typing import List
import uuid

from app.database import get_db
from app.core.auth import get_current_admin, get_current_admin_optional
from app.core.telegram_webapp_auth import (
    get_telegram_user_id_from_init_data,
    require_telegram_identity,
)
router = APIRouter()


def _extract_delivery_info(order) -> tuple[float | None, str | None]:
    """Извлечь delivery_cost и delivery_method из order_metadata."""
    delivery_cost = None
    delivery_method = None
    if order.order_metadata:
        delivery_cost = order.order_metadata.get("delivery_cost")
        delivery_method = order.order_metadata.get("delivery_method")
    return delivery_cost, delivery_method


class OrderItemRequest(BaseModel):
    """Элемент заказа в запросе."""

    product_id: uuid.UUID
    quantity: int
    note: str | None = None
    selected_variations: dict[str, str] | None = None  # Выбранные вариации {ключ: значение}


class CreateOrderRequest(BaseModel):
    """Запрос на создание заказа."""

    customer_name: str | None = None
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
    total_amount: float  # Итоговая сумма (включая доставку)
    delivery_cost: float | None = None  # Стоимость доставки
    delivery_method: str | None = None  # Способ доставки
    payment: PaymentResponse | None = None


@router.post("/{business_slug}/orders", response_model=CreateOrderResponse)
async def create_order(
    business_slug: str,
    request: CreateOrderRequest,
    db: AsyncSession = Depends(get_db),
    x_telegram_init_data: str | None = Header(None, alias="X-Telegram-Init-Data"),
):
    """
    Создать заказ.

    Backend валидирует товары, перечитывает цены из БД и вычисляет итоговую сумму.
    Если передан user_telegram_id, заголовок X-Telegram-Init-Data обязателен и должен совпадать с id.
    """
    from app.services.order_service import OrderService
    from fastapi import HTTPException, status

    if request.user_telegram_id is not None:
        tid = get_telegram_user_id_from_init_data(x_telegram_init_data)
        if tid is None:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Для указания user_telegram_id требуется валидный заголовок X-Telegram-Init-Data",
            )
        if tid != request.user_telegram_id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="user_telegram_id не совпадает с подписью Telegram WebApp",
            )

    service = OrderService(db)

    try:
        # Преобразуем items в нужный формат
        items_data = [
            {
                "product_id": str(item.product_id),
                "quantity": item.quantity,
                "note": item.note,
                "selected_variations": item.selected_variations or {},
            }
            for item in request.items
        ]

        from decimal import Decimal

        # В Mini App имя вручную больше не вводится: при наличии Telegram ID
        # сохраняем техническое имя на основе него.
        effective_customer_name = (
            f"tg_{request.user_telegram_id}"
            if request.user_telegram_id is not None
            else (request.customer_name or "guest")
        )

        order = await service.create_order(
            business_slug=business_slug,
            customer_name=effective_customer_name,
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
            return_url = f"https://t.me/TG_shop_402_bot?start=order_{order.id}"
            
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

        # Извлекаем delivery_cost и delivery_method из order_metadata
        delivery_cost = None
        delivery_method = None
        if order.order_metadata:
            delivery_cost = order.order_metadata.get("delivery_cost")
            delivery_method = order.order_metadata.get("delivery_method")

        return CreateOrderResponse(
            order_id=order.id,
            total_amount=float(order.total_amount),
            delivery_cost=float(delivery_cost) if delivery_cost is not None else None,
            delivery_method=delivery_method,
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
    subtotal_amount: float | None = None  # Сумма до скидок (включая доставку)
    discount_amount: float | None = None  # Общая сумма скидки
    delivery_cost: float | None = None  # Стоимость доставки
    delivery_method: str | None = None  # Способ доставки (pickup/delivery)
    currency: str
    status: str
    payment_status: str
    payment_method: str
    created_at: str
    updated_at: str
    items: List[OrderItemResponse]


def _create_order_response(order) -> OrderResponse:
    """Создать OrderResponse из Order с полной информацией."""
    delivery_cost, delivery_method = _extract_delivery_info(order)
    
    return OrderResponse(
        id=order.id,
        customer_name=order.customer_name,
        customer_phone=order.customer_phone,
        customer_address=order.customer_address,
        total_amount=float(order.total_amount),
        subtotal_amount=float(order.subtotal_amount) if order.subtotal_amount else None,
        discount_amount=float(order.discount_amount) if order.discount_amount else None,
        delivery_cost=float(delivery_cost) if delivery_cost is not None else None,
        delivery_method=delivery_method,
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


@router.get("/{business_slug}/orders", response_model=List[OrderResponse])
async def get_orders(
    business_slug: str,
    page: int = 1,
    limit: int = 20,
    db: AsyncSession = Depends(get_db),
    current_admin: dict = Depends(get_current_admin),
):
    """
    Получить список заказов бизнеса (для админки).
    
    Требует авторизации администратора.
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
        result.append(_create_order_response(order))

    return result


@router.get("/orders/{order_id}", response_model=OrderResponse)
async def get_order(
    order_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    admin_payload: dict | None = Depends(get_current_admin_optional),
    x_telegram_init_data: str | None = Header(None, alias="X-Telegram-Init-Data"),
):
    """
    Получить заказ по ID.

    Доступ: администратор с Bearer JWT или владелец заказа (совпадение user_telegram_id с init_data).
    """
    from app.services.order_service import OrderService

    service = OrderService(db)
    order = await service.get_by_id(order_id)

    if admin_payload is not None:
        if not order:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Заказ с ID '{order_id}' не найден",
            )
        return _create_order_response(order)

    if not order:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Заказ с ID '{order_id}' не найден",
        )

    # Гостевой заказ (без привязки к Telegram) доступен любому, кто знает UUID:
    # сам UUID непредсказуем и выполняет роль capability-токена.
    if order.user_telegram_id is None:
        return _create_order_response(order)

    if x_telegram_init_data is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Требуется Bearer JWT администратора или заголовок X-Telegram-Init-Data",
        )

    viewer_tid = get_telegram_user_id_from_init_data(x_telegram_init_data)
    if viewer_tid is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Невалидные данные в заголовке X-Telegram-Init-Data",
        )

    if order.user_telegram_id != viewer_tid:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Нет доступа к этому заказу",
        )

    return _create_order_response(order)


@router.post("/orders/{order_id}/cancel", response_model=OrderResponse)
async def cancel_order(
    order_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_admin: dict = Depends(get_current_admin),
):
    """
    Отменить заказ (только для администратора).
    
    Заказ можно отменить только если его статус 'new' или 'accepted'.
    
    Требует авторизации администратора.
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

    return _create_order_response(order)


@router.get("/orders/user/{user_telegram_id}", response_model=List[OrderResponse])
async def get_user_orders(
    user_telegram_id: int,
    business_slug: str | None = None,
    page: int = 1,
    limit: int = 20,
    db: AsyncSession = Depends(get_db),
    viewer_tid: int = Depends(require_telegram_identity),
):
    """
    Получить заказы пользователя по Telegram ID.

    Доступ только к своим заказам: id в пути должен совпадать с подписью init_data.
    """
    if viewer_tid != user_telegram_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Нельзя запрашивать чужие заказы",
        )

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
        result.append(_create_order_response(order))

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
    current_admin: dict = Depends(get_current_admin),
):
    """
    Обновить статус заказа и/или статус оплаты.
    
    Требует авторизации администратора.
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

    return _create_order_response(order)
