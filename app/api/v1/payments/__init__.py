"""Payments API."""
from fastapi import APIRouter, Depends, HTTPException, status, Request
from sqlalchemy.ext.asyncio import AsyncSession
from pydantic import BaseModel
import hmac
import hashlib
import logging

from app.database import get_db
from app.services.payment_service import PaymentService
from app.config import settings

logger = logging.getLogger(__name__)

router = APIRouter()


class YooKassaWebhookRequest(BaseModel):
    """Webhook запрос от YooKassa."""

    type: str
    event: str
    object: dict


@router.post("/webhook/yookassa")
async def yookassa_webhook(
    request: Request,
    db: AsyncSession = Depends(get_db),
):
    """
    Webhook для обработки событий от YooKassa.

    Проверяет подпись и обрабатывает события платежей.
    """
    logger.info("=== YooKassa Webhook received ===")
    logger.info(f"Headers: {dict(request.headers)}")
    
    # Получаем тело запроса
    body = await request.body()
    logger.info(f"Body length: {len(body)} bytes")
    logger.debug(f"Body content: {body.decode('utf-8') if body else 'empty'}")
    
    signature = request.headers.get("X-YooMoney-Signature")
    logger.info(f"Signature header: {signature}")

    # Проверка подписи (если настроен webhook secret)
    if settings.yookassa_webhook_secret and signature:
        logger.info("Webhook secret is configured, validating signature...")
        expected_signature = hmac.new(
            settings.yookassa_webhook_secret.encode(),
            body,
            hashlib.sha256,
        ).hexdigest()

        logger.debug(f"Expected signature: {expected_signature}")
        logger.debug(f"Received signature: {signature}")

        if signature != expected_signature:
            logger.error("❌ Invalid webhook signature!")
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid signature",
            )
        logger.info("✅ Signature validated successfully")
    else:
        logger.warning("⚠️ Webhook secret not configured or signature header missing - skipping signature validation")

    # Парсим данные
    import json
    try:
        event_data = await request.json()
        logger.info(f"Event data parsed: {json.dumps(event_data, indent=2, ensure_ascii=False)}")
    except Exception as e:
        logger.error(f"❌ Failed to parse JSON: {e}")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid JSON",
        )

    # Обрабатываем webhook
    logger.info("Processing webhook with PaymentService...")
    service = PaymentService(db)
    payment = await service.process_yookassa_webhook(event_data)

    if payment:
        logger.info(f"✅ Payment processed successfully: {payment.id}, status: {payment.status}")
        return {"ok": True, "payment_id": str(payment.id)}
    else:
        logger.info("ℹ️ Event processed but no payment updated (event type not handled or payment not found)")
        return {"ok": True, "message": "Event processed"}

