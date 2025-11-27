# Быстрый старт

## 1. Запуск через Docker Compose

```bash
# Запустить все сервисы (PostgreSQL, Redis, Backend)
docker-compose up -d

# Проверить логи
docker-compose logs -f backend

# Остановить
docker-compose down
```

## 2. Создание первой миграции

```bash
# Войти в контейнер backend
docker-compose exec backend bash

# Создать миграцию
alembic revision --autogenerate -m "Initial migration"

# Применить миграции
alembic upgrade head
```

Или локально (если установлен Python и зависимости):

```bash
# Активировать виртуальное окружение
source venv/bin/activate  # или venv\Scripts\activate на Windows

# Установить зависимости
pip install -r requirements.txt

# Создать миграцию
alembic revision --autogenerate -m "Initial migration"

# Применить миграции
alembic upgrade head

# Запустить сервер
uvicorn app.main:app --reload
```

## 3. Проверка работы

1. Откройте http://localhost:8000/docs - Swagger UI
2. Проверьте health endpoint: http://localhost:8000/health
3. Протестируйте админ-авторизацию: `POST /api/v1/admin/login`

## 4. Тестирование админ-авторизации

```bash
curl -X POST "http://localhost:8000/api/v1/admin/login" \
  -H "Content-Type: application/json" \
  -d '{"password": "admin123"}'
```

Ответ должен содержать `access_token`.

## 5. Переменные окружения

Создайте файл `.env` на основе `.env.example`:

```bash
cp .env.example .env
```

Важные переменные:
- `DATABASE_URL` - подключение к PostgreSQL
- `SECRET_KEY` - секретный ключ для JWT (измените в продакшене!)
- `ADMIN_PASSWORD` - пароль администратора (по умолчанию: admin123)

