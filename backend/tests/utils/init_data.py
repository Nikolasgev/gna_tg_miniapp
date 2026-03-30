"""Генерация валидной строки init_data для тестов (HMAC как в app.core.telegram)."""
from __future__ import annotations

import hashlib
import hmac
import json
from urllib.parse import urlencode


def build_webapp_init_data(
    bot_token: str,
    *,
    user_id: int,
    first_name: str = "Test",
    username: str | None = "testuser",
    auth_date: int = 1_700_000_000,
) -> str:
    """
    Собирает query-string init_data с полем hash, совместимый с validate_telegram_init_data.

    Формат data_check_string совпадает с разбором через urllib.parse.parse_qs в app.core.telegram.
    """
    user_obj: dict = {"id": user_id, "first_name": first_name}
    if username is not None:
        user_obj["username"] = username
    user_str = json.dumps(user_obj, separators=(",", ":"))
    auth_str = str(auth_date)

    pairs_for_check = [("auth_date", auth_str), ("user", user_str)]
    pairs_for_check.sort(key=lambda x: x[0])
    data_check_string = "\n".join(f"{k}={v}" for k, v in pairs_for_check)

    secret_key = hmac.new(
        b"WebAppData",
        bot_token.encode(),
        hashlib.sha256,
    ).digest()
    calculated_hash = hmac.new(
        secret_key,
        data_check_string.encode(),
        hashlib.sha256,
    ).hexdigest()

    query = urlencode({"user": user_str, "auth_date": auth_str})
    return f"{query}&hash={calculated_hash}"
