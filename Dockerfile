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
EXPOSE 8000

# Делаем start.sh исполняемым
COPY start.sh /app/start.sh
RUN chmod +x /app/start.sh

# Команда по умолчанию (Railway переопределит через startCommand)
CMD ["./start.sh"]

