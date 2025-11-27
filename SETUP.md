# Инструкция по настройке

## Важно: Версия Python

Проект требует **Python 3.11 или 3.12**. Python 3.14 пока не поддерживается некоторыми зависимостями.

## Проверка версии Python

```bash
python3 --version
# Должно быть: Python 3.11.x или Python 3.12.x
```

Если у вас Python 3.14, установите Python 3.11 или 3.12 через:
- Homebrew: `brew install python@3.11`
- pyenv: `pyenv install 3.11.9`

## Установка через Docker (рекомендуется)

Самый простой способ - использовать Docker Compose:

```bash
docker-compose up -d
```

Это автоматически установит все зависимости и запустит сервисы.

## Локальная установка

### 1. Создание виртуального окружения

```bash
# Убедитесь, что используете Python 3.11 или 3.12
python3.11 -m venv venv
# или
python3.12 -m venv venv

# Активация
source venv/bin/activate  # macOS/Linux
# или
venv\Scripts\activate  # Windows
```

### 2. Установка зависимостей

```bash
pip install --upgrade pip
pip install -r requirements.txt
```

### 3. Настройка переменных окружения

```bash
cp .env.example .env
# Отредактируйте .env файл
```

### 4. Запуск миграций

```bash
# Создать миграцию
alembic revision --autogenerate -m "Initial migration"

# Применить миграции
alembic upgrade head
```

### 5. Запуск сервера

```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

## Использование Alembic

После активации виртуального окружения:

```bash
# Активировать venv
source venv/bin/activate

# Теперь alembic доступен
alembic revision --autogenerate -m "Initial migration"
alembic upgrade head
```

