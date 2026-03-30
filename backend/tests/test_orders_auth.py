"""Проверки, что публичные эндпоинты заказов требуют Telegram init_data или JWT."""
import uuid

from starlette.testclient import TestClient


def test_get_order_without_credentials_returns_401(client: TestClient) -> None:
    oid = uuid.uuid4()
    r = client.get(f"/api/v1/orders/orders/{oid}")
    assert r.status_code == 401


def test_get_user_orders_without_header_returns_401(client: TestClient) -> None:
    r = client.get("/api/v1/orders/orders/user/123456789")
    assert r.status_code == 401
