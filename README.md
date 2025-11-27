# Telegram Mini App Builder - Backend

Backend API для конструктора Telegram Mini App на FastAPI.

## Технологический стек

- **FastAPI** - веб-фреймворк
- **PostgreSQL** - база данных
- **Redis** - кэширование
- **SQLAlchemy** (async) - ORM
- **Alembic** - миграции БД

## Требования

- **Python 3.11 или 3.12** (Python 3.14 не поддерживается)
- **PostgreSQL 15+** (локально или через Docker)
- **Redis** (локально или через Docker)
- **Docker** (опционально, для упрощения запуска)

## Быстрый старт

**Важно:** Проект требует Python 3.11 или 3.12. Python 3.14 не поддерживается.

### Вариант 1: С Docker (рекомендуется)

#### 1. Запуск Docker Desktop

Убедитесь, что Docker Desktop запущен на вашем Mac.

#### 2. Запуск всех сервисов

```bash
docker-compose up -d
```

Это запустит:
- PostgreSQL на порту 5432
- Redis на порту 6379
- Backend на порту 8000

#### 3. Создание миграций

```bash
# Войти в контейнер backend
docker-compose exec backend bash

# Создать миграцию
alembic revision --autogenerate -m "Initial migration"

# Применить миграции
alembic upgrade head
```

#### 4. Проверка работы

Откройте http://localhost:8000/docs - Swagger UI

### Вариант 2: Локальный запуск (без Docker)

#### 1. Установка зависимостей

```bash
# Используйте Python 3.11 или 3.12
python3.11 -m venv venv
# или
python3.12 -m venv venv

source venv/bin/activate  # Windows: venv\Scripts\activate
pip install --upgrade pip
pip install -r requirements.txt
```

#### 2. Настройка переменных окружения

```bash
cp .env.example .env
# Отредактируйте .env файл
```

#### 3. Запуск PostgreSQL и Redis

**Через Docker (если Docker доступен):**
```bash
docker run -d --name postgres -p 5432:5432 \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_DB=tg_store_db \
  postgres:15-alpine

docker run -d --name redis -p 6379:6379 redis:7-alpine
```

**Или установите локально:**
- PostgreSQL: `brew install postgresql@15` и `brew services start postgresql@15`
- Redis: `brew install redis` и `brew services start redis`

#### 4. Создание миграций

```bash
# Активируйте виртуальное окружение
source venv/bin/activate

# Создать миграцию
alembic revision --autogenerate -m "Initial migration"

# Применить миграции
alembic upgrade head
```

#### 5. Запуск сервера

```bash
# Используйте скрипт
./run_local.sh

# Или вручную
source venv/bin/activate
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

## Структура проекта

```
backend/
├── app/
│   ├── main.py              # Точка входа
│   ├── config.py            # Конфигурация
│   ├── database.py          # Подключение к БД
│   ├── models/              # SQLAlchemy модели
│   ├── schemas/             # Pydantic схемы
│   ├── api/                 # API роутеры
│   ├── core/                # Ядро (auth, security)
│   └── services/            # Бизнес-логика
├── alembic/                 # Миграции БД
├── tests/                   # Тесты
├── requirements.txt
└── docker-compose.yml
```

## API Документация

После запуска сервера доступна по адресу:
- Swagger UI: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc

## Разработка

### Настройка Alembic

Перед первым запуском нужно настроить Alembic:

1. Обновите `alembic.ini` - замените `sqlalchemy.url` на ваш DATABASE_URL
2. Или используйте переменную окружения: `export DATABASE_URL=...`

### Создание миграций

```bash
# Создать новую миграцию
alembic revision --autogenerate -m "Initial migration"

# Применить миграции
alembic upgrade head

# Откатить миграцию
alembic downgrade -1
```

### Линтинг

```bash
black app/
isort app/
flake8 app/
```

### Тесты

```bash
pytest
```

## Структура API

### Админ-авторизация

- `POST /api/v1/admin/login` - Авторизация по паролю
  - Body: `{"password": "string"}`
  - Response: `{"ok": true, "access_token": "...", "message": "..."}`

### Telegram

- `POST /api/v1/telegram/validate_init_data` - Валидация init_data (TODO)

### Бизнесы

- `GET /api/v1/businesses/{slug}` - Получить информацию о бизнесе
- `POST /api/v1/businesses` - Создать бизнес (TODO)

### Продукты

- `GET /api/v1/products/{business_slug}/products` - Список продуктов

### Заказы

- `POST /api/v1/orders/{business_slug}/orders` - Создать заказ

## Устранение проблем

### Docker daemon не запущен

Если видите ошибку "Cannot connect to the Docker daemon":
1. Запустите Docker Desktop
2. Дождитесь полного запуска (иконка в меню должна быть зеленая)
3. Попробуйте снова: `docker-compose up -d`

### Alembic не найден

Убедитесь, что виртуальное окружение активировано:
```bash
source venv/bin/activate
alembic --version
```

### Проблемы с Python 3.14

Если у вас Python 3.14, установите Python 3.11 или 3.12:
```bash
brew install python@3.11
python3.11 -m venv venv
```

Подробнее см. [SETUP.md](SETUP.md)
