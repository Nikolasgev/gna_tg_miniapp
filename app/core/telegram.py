"""Утилиты для работы с Telegram."""
import hashlib
import hmac
from urllib.parse import parse_qs, unquote
from typing import Dict, Any


def validate_telegram_init_data(init_data: str, bot_token: str) -> Dict[str, Any] | None:
    """
    Валидация init_data от Telegram WebApp.

    Args:
        init_data: Строка init_data от Telegram
        bot_token: Токен бота от BotFather

    Returns:
        Словарь с данными пользователя или None если валидация не прошла
    """
    try:
        # Парсим init_data
        parsed = parse_qs(init_data)
        
        # Извлекаем hash и остальные данные
        received_hash = parsed.get('hash', [None])[0]
        if not received_hash:
            return None
        
        # Удаляем hash из данных для проверки
        data_check = []
        for key, value in parsed.items():
            if key != 'hash':
                data_check.append(f"{key}={value[0]}")
        
        # Сортируем для консистентности
        data_check.sort()
        data_check_string = '\n'.join(data_check)
        
        # Создаем секретный ключ
        secret_key = hmac.new(
            "WebAppData".encode(),
            bot_token.encode(),
            hashlib.sha256
        ).digest()
        
        # Вычисляем hash
        calculated_hash = hmac.new(
            secret_key,
            data_check_string.encode(),
            hashlib.sha256
        ).hexdigest()
        
        # Проверяем hash
        if calculated_hash != received_hash:
            return None
        
        # Извлекаем данные пользователя
        user_data = {}
        if 'user' in parsed:
            user_str = unquote(parsed['user'][0])
            import json
            user_data = json.loads(user_str)
        
        return user_data
        
    except Exception:
        return None


def extract_telegram_user(init_data: str, bot_token: str) -> Dict[str, Any] | None:
    """
    Извлекает данные пользователя Telegram из валидированного init_data.
    
    Returns:
        {
            "id": int,
            "first_name": str,
            "username": str | None,
            ...
        }
    """
    return validate_telegram_init_data(init_data, bot_token)

