"""Сервис для работы с платежами."""
import uuid
import logging
from decimal import Decimal
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.payment import Payment
from app.models.order import Order
from app.config import settings

logger = logging.getLogger(__name__)


class PaymentService:
    """Сервис для работы с платежами."""

    def __init__(self, db: AsyncSession):
        self.db = db

    async def create_yookassa_payment(
        self,
        order: Order,
        return_url: str,
    ) -> dict:
        """
        Создать платеж в YooKassa.

        Returns:
            {
                "id": "payment_id",
                "status": "pending",
                "confirmation": {
                    "confirmation_url": "https://..."
                }
            }
        """
        import httpx

        if not settings.yookassa_secret_key:
            raise ValueError("YooKassa secret key not configured")
        
        if not settings.yookassa_shop_id:
            raise ValueError("YooKassa shop ID not configured")

        # Подготовка данных для YooKassa
        # YooKassa требует строку с точкой как разделителем (например "350.00")
        # Форматируем Decimal в строку с 2 знаками после запятой
        amount_value = f"{float(order.total_amount):.2f}"
        logger.info(f"Creating YooKassa payment for order {order.id}: amount={amount_value} {order.currency}")
        
        payment_data = {
            "amount": {
                "value": amount_value,
                "currency": order.currency,
            },
            "confirmation": {
                "type": "redirect",
                "return_url": return_url,
            },
            "capture": True,
            "description": f"Заказ #{order.id}",
            "metadata": {
                "order_id": str(order.id),
            },
        }

        # Подготовка авторизации для YooKassa
        # YooKassa использует Basic Auth с shop_id:secret_key в base64
        import base64
        auth_string = f"{settings.yookassa_shop_id}:{settings.yookassa_secret_key}"
        auth_bytes = base64.b64encode(auth_string.encode()).decode()

        # Создание платежа через YooKassa API
        async with httpx.AsyncClient() as client:
            response = await client.post(
                "https://api.yookassa.ru/v3/payments",
                json=payment_data,
                headers={
                    "Authorization": f"Basic {auth_bytes}",
                    "Content-Type": "application/json",
                    "Idempotence-Key": str(uuid.uuid4()),
                },
                timeout=30.0,
            )

            if response.status_code != 200:
                raise ValueError(f"YooKassa API error: {response.text}")

            payment_info = response.json()

        # Сохраняем платеж в БД
        payment = Payment(
            order_id=order.id,
            provider="yookassa",
            provider_payment_id=payment_info["id"],
            amount=order.total_amount,
            status=payment_info["status"],
            raw_payload=payment_info,
        )

        self.db.add(payment)
        await self.db.commit()
        await self.db.refresh(payment)

        # Логируем полный ответ от YooKassa для отладки
        logger.info(f"YooKassa payment response: {payment_info}")
        
        # Проверяем наличие confirmation_url
        confirmation = payment_info.get("confirmation", {})
        confirmation_url = confirmation.get("confirmation_url")
        
        if not confirmation_url:
            logger.error(f"YooKassa payment created but no confirmation_url found. Response: {payment_info}")
            raise ValueError("YooKassa payment created but no confirmation_url in response")
        
        logger.info(f"YooKassa confirmation_url: {confirmation_url}")
        
        return {
            "id": payment_info["id"],
            "status": payment_info["status"],
            "confirmation": confirmation,
        }

    async def process_yookassa_webhook(self, event_data: dict) -> Payment | None:
        """
        Обработать webhook от YooKassa.

        Args:
            event_data: Данные события от YooKassa

        Returns:
            Payment объект или None
        """
        logger.info("=== Processing YooKassa webhook ===")
        logger.info(f"Event data: {event_data}")
        
        event_type = event_data.get("event")
        logger.info(f"Event type: {event_type}")
        
        payment_object = event_data.get("object", {})
        logger.info(f"Payment object: {payment_object}")

        if event_type != "payment.succeeded":
            logger.info(f"Event type '{event_type}' is not 'payment.succeeded', skipping")
            return None

        provider_payment_id = payment_object.get("id")
        logger.info(f"Provider payment ID: {provider_payment_id}")
        
        if not provider_payment_id:
            logger.warning("⚠️ No provider_payment_id in payment object")
            return None

        # Находим платеж
        logger.info(f"Searching for payment with provider_payment_id: {provider_payment_id}")
        stmt = select(Payment).where(
            Payment.provider == "yookassa",
            Payment.provider_payment_id == provider_payment_id,
        )
        result = await self.db.execute(stmt)
        payment = result.scalar_one_or_none()

        if not payment:
            logger.warning(f"⚠️ Payment not found for provider_payment_id: {provider_payment_id}")
            return None

        logger.info(f"✅ Payment found: {payment.id}, current status: {payment.status}")
        logger.info(f"Order ID: {payment.order_id}")

        # Обновляем статус
        new_status = payment_object.get("status", "pending")
        logger.info(f"Updating payment status from '{payment.status}' to '{new_status}'")
        payment.status = new_status
        payment.raw_payload = payment_object

        # Обновляем статус заказа
        stmt_order = select(Order).where(Order.id == payment.order_id)
        result_order = await self.db.execute(stmt_order)
        order = result_order.scalar_one_or_none()

        if order:
            logger.info(f"Order found: {order.id}, current payment_status: {order.payment_status}")
            if payment.status == "succeeded":
                logger.info("✅ Payment succeeded, updating order payment_status to 'paid'")
                order.payment_status = "paid"
                
                # Начисляем баллы лояльности за оплаченный заказ
                try:
                    from app.services.order_service import OrderService
                    order_service = OrderService(self.db)
                    awarded = await order_service.award_loyalty_points(order.id)
                    if awarded:
                        logger.info(f"✅ Loyalty points awarded for order {order.id}")
                    else:
                        logger.info(f"ℹ️ Loyalty points already awarded or not applicable for order {order.id}")
                except Exception as e:
                    logger.error(f"❌ Error awarding loyalty points for order {order.id}: {e}", exc_info=True)
                    # Не прерываем обработку платежа из-за ошибки начисления баллов
            elif payment.status == "canceled":
                logger.info("❌ Payment canceled, updating order payment_status to 'failed'")
                order.payment_status = "failed"
            else:
                logger.info(f"Payment status is '{payment.status}', not updating order payment_status")
        else:
            logger.warning(f"⚠️ Order not found for payment.order_id: {payment.order_id}")

        self.db.add(payment)
        if order:
            self.db.add(order)
        
        await self.db.commit()
        await self.db.refresh(payment)
        
        if order:
            await self.db.refresh(order)
            logger.info(f"✅ Order payment_status updated to: {order.payment_status}")

        logger.info(f"✅ Payment webhook processed successfully: {payment.id}")
        return payment

    async def get_by_order_id(self, order_id: uuid.UUID) -> Payment | None:
        """Получить платеж по ID заказа."""
        stmt = select(Payment).where(Payment.order_id == order_id)
        result = await self.db.execute(stmt)
        return result.scalar_one_or_none()

