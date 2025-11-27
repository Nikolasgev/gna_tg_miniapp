FROM python:3.11-slim

WORKDIR /app

# Установка системных зависимостей
RUN apt-get update && apt-get install -y \
    gcc \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/*

# Копирование зависимостей
COPY requirements.txt .

# Установка Python зависимостей
RUN pip install --no-cache-dir -r requirements.txt

# Копирование кода приложения
COPY . .

# Открытие порта (Railway использует переменную PORT)
EXPOSE ${PORT:-8000}

# Команда по умолчанию
# Railway переопределит это через startCommand в railway.json
CMD uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-8000}

