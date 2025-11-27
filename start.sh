#!/bin/bash
# Скрипт запуска для Railway

# Получаем порт из переменной окружения или используем 8000 по умолчанию
PORT=${PORT:-8000}

echo "Starting application on port $PORT"

# Запускаем uvicorn
exec uvicorn app.main:app --host 0.0.0.0 --port $PORT

