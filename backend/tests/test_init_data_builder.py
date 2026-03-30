"""Юнит-тест генератора init_data (без БД)."""
from app.core.telegram import extract_telegram_user

from tests.utils.init_data import build_webapp_init_data


def test_build_webapp_init_data_passes_backend_validation() -> None:
    token = "123456:ABC-DEF_test_token"
    uid = 424242
    init = build_webapp_init_data(token, user_id=uid, username="ci_user")
    user = extract_telegram_user(init, token)
    assert user is not None
    assert user["id"] == uid
    assert user.get("username") == "ci_user"
