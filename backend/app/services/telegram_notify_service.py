"""Уведомления покупателю через Telegram Bot API."""
from __future__ import annotations

import html
import logging
from decimal import Decimal
from typing import TYPE_CHECKING

import httpx

from app.config import settings

if TYPE_CHECKING:
    from app.models.order import Order

logger = logging.getLogger(__name__)


def _format_money(amount: Decimal | float, currency: str) -> str:
    return f"{float(amount):.2f} {currency}".strip()


async def send_order_confirmation_message(
    *,
    user_telegram_id: int,
    business_name: str,
    order_id,
    customer_name: str,
    total_amount: Decimal,
    currency: str,
    payment_method: str,
    delivery_method: str | None,
    delivery_cost: float | None,
    items_lines: list[tuple[str, int, Decimal]],
) -> bool:
    """
    Отправить пользователю сообщение о новом заказе (HTTPS Bot API).

    Returns:
        True если запрос к Telegram успешен, иначе False.
    """
    token = (settings.telegram_bot_token or "").strip()
    if not token:
        logger.debug("telegram_bot_token не задан — уведомление о заказе не отправляется")
        return False

    pay_ru = "онлайн" if payment_method == "online" else "при получении"
    del_ru = "доставка" if delivery_method == "delivery" else "самовывоз"

    lines: list[str] = [
        "✅ <b>Заказ оформлен</b>",
        "",
        f"Магазин: {html.escape(business_name)}",
        f"Номер: <code>{order_id}</code>",
        f"Имя: {html.escape(customer_name)}",
        f"Оплата: {html.escape(pay_ru)}",
        f"Получение: {html.escape(del_ru)}",
        "",
        "<b>Состав:</b>",
    ]
    for title, qty, line_total in items_lines:
        lines.append(
            f"• {html.escape(title)} × {qty} — {_format_money(line_total, currency)}"
        )
    if delivery_cost is not None and delivery_cost > 0 and delivery_method == "delivery":
        lines.append(f"• Доставка — {_format_money(Decimal(str(delivery_cost)), currency)}")
    lines.append("")
    lines.append(f"<b>Итого: {_format_money(total_amount, currency)}</b>")

    text = "\n".join(lines)
    url = f"https://api.telegram.org/bot{token}/sendMessage"

    try:
        async with httpx.AsyncClient(timeout=15.0) as client:
            resp = await client.post(
                url,
                json={
                    "chat_id": user_telegram_id,
                    "text": text,
                    "parse_mode": "HTML",
                    "disable_web_page_preview": True,
                },
            )
        if resp.status_code != 200:
            logger.warning(
                "Telegram sendMessage failed: %s %s",
                resp.status_code,
                resp.text[:500],
            )
            return False
        data = resp.json()
        if not data.get("ok"):
            logger.warning("Telegram API ok=false: %s", data)
            return False
        return True
    except Exception as e:
        logger.error("Ошибка отправки уведомления в Telegram: %s", e, exc_info=True)
        return False


async def notify_order_created(order: "Order") -> bool:
    """Отправить подтверждение заказа, если у заказа есть user_telegram_id и загружены items + business."""
    if not order.user_telegram_id:
        return False
    business = order.business
    business_name = business.name if business else "Магазин"
    meta = order.order_metadata or {}
    delivery_method = meta.get("delivery_method")
    delivery_cost = meta.get("delivery_cost")
    items_lines = [
        (item.title_snapshot, item.quantity, item.total_price) for item in (order.items or [])
    ]
    return await send_order_confirmation_message(
        user_telegram_id=order.user_telegram_id,
        business_name=business_name,
        order_id=str(order.id),
        customer_name=order.customer_name,
        total_amount=order.total_amount,
        currency=order.currency,
        payment_method=order.payment_method,
        delivery_method=delivery_method,
        delivery_cost=float(delivery_cost) if delivery_cost is not None else None,
        items_lines=items_lines,
    )
