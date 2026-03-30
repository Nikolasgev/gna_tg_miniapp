"""
Интеграционные тесты с PostgreSQL.

Запуск локально: RUN_INTEGRATION_TESTS=1 DATABASE_URL=postgresql+asyncpg://... pytest tests/test_integration_api.py
В CI включаются автоматически (CI=true).
"""
from __future__ import annotations

import os
import uuid
from decimal import Decimal

import pytest
import pytest_asyncio
from sqlalchemy import delete, select
from starlette.testclient import TestClient

from app.config import settings
from app.database import AsyncSessionLocal
from app.main import app
from app.models.business import Business
from app.models.order import Order, OrderItem
from app.models.product import Product
from app.models.user import User
from tests.utils.init_data import build_webapp_init_data

pytestmark = pytest.mark.integration

# Совпадает с заголовком X-Telegram-Init-Data и user в init_data
_CI_TELEGRAM_UID = 887766554


@pytest_asyncio.fixture
async def seeded_shop() -> dict:
    """Создаёт владельца, бизнес и один товар; после теста удаляет данные."""
    slug = f"ci-{uuid.uuid4().hex[:12]}"
    owner_username = f"owner_{slug}"
    business_id: uuid.UUID | None = None
    owner_id: uuid.UUID | None = None
    product_id: uuid.UUID | None = None

    async with AsyncSessionLocal() as session:
        owner = User(role="owner", username=owner_username)
        session.add(owner)
        await session.flush()
        owner_id = owner.id
        business = Business(
            owner_id=owner.id,
            name="CI Shop",
            slug=slug,
        )
        session.add(business)
        await session.flush()
        business_id = business.id
        product = Product(
            business_id=business.id,
            title="CI Product",
            price=Decimal("150.00"),
            is_active=True,
            stock_quantity=50,
        )
        session.add(product)
        await session.commit()
        await session.refresh(product)
        product_id = product.id

    data = {
        "slug": slug,
        "product_id": str(product_id),
        "business_id": business_id,
        "owner_id": owner_id,
        "telegram_uid": _CI_TELEGRAM_UID,
    }
    yield data

    assert business_id and owner_id and product_id
    async with AsyncSessionLocal() as session:
        order_ids = (
            await session.execute(select(Order.id).where(Order.business_id == business_id))
        ).scalars().all()
        if order_ids:
            await session.execute(delete(OrderItem).where(OrderItem.order_id.in_(order_ids)))
            await session.execute(delete(Order).where(Order.id.in_(order_ids)))
        await session.execute(delete(Product).where(Product.id == product_id))
        await session.execute(delete(Business).where(Business.id == business_id))
        await session.execute(delete(User).where(User.id == owner_id))
        await session.execute(delete(User).where(User.telegram_id == _CI_TELEGRAM_UID))
        await session.commit()


@pytest.fixture
def integration_client() -> TestClient:
    return TestClient(app)


def test_validate_init_data_persists_client(
    integration_client: TestClient,
    seeded_shop: dict,
) -> None:
    if not settings.telegram_bot_token:
        pytest.skip("TELEGRAM_BOT_TOKEN должен быть задан для проверки подписи")
    init = build_webapp_init_data(
        settings.telegram_bot_token,
        user_id=seeded_shop["telegram_uid"],
        username="ci_buyer",
    )
    r = integration_client.post(
        "/api/v1/telegram/validate_init_data",
        json={"init_data": init},
    )
    assert r.status_code == 200
    body = r.json()
    assert body.get("ok") is True
    assert body.get("telegram_user", {}).get("id") == seeded_shop["telegram_uid"]


def test_create_cash_order_with_init_data_header(
    integration_client: TestClient,
    seeded_shop: dict,
) -> None:
    if not settings.telegram_bot_token:
        pytest.skip("TELEGRAM_BOT_TOKEN должен быть задан для проверки подписи")
    init = build_webapp_init_data(
        settings.telegram_bot_token,
        user_id=seeded_shop["telegram_uid"],
        username="ci_buyer",
    )
    payload = {
        "customer_name": "CI User",
        "customer_phone": "+70000000000",
        "items": [
            {
                "product_id": seeded_shop["product_id"],
                "quantity": 2,
            },
        ],
        "payment_method": "cash",
        "delivery_method": "pickup",
        "user_telegram_id": seeded_shop["telegram_uid"],
    }
    r = integration_client.post(
        f"/api/v1/orders/{seeded_shop['slug']}/orders",
        json=payload,
        headers={"X-Telegram-Init-Data": init},
    )
    assert r.status_code == 200, r.text
    data = r.json()
    assert "order_id" in data
    assert data.get("payment") is None
    assert float(data.get("total_amount", 0)) == 300.0
