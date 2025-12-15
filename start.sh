#!/bin/bash
# Скрипт запуска для Railway

# Получаем порт из переменной окружения или используем 8000 по умолчанию
PORT=${PORT:-8000}

echo "Starting application on port $PORT"
echo "Environment variables:"
env | grep -E "PORT|DATABASE|ENVIRONMENT" || true

# Запускаем uvicorn с дополнительными опциями для production
exec uvicorn app.main:app --host 0.0.0.0 --port $PORT --workers 1 --log-level info

