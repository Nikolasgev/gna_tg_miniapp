.PHONY: help install dev up down migrate upgrade downgrade test lint format

help:
	@echo "Доступные команды:"
	@echo "  make install    - Установить зависимости"
	@echo "  make dev        - Запустить в режиме разработки"
	@echo "  make up         - Запустить Docker Compose"
	@echo "  make down       - Остановить Docker Compose"
	@echo "  make migrate    - Создать новую миграцию"
	@echo "  make upgrade    - Применить миграции"
	@echo "  make downgrade  - Откатить миграцию"
	@echo "  make test       - Запустить тесты"
	@echo "  make lint       - Проверить код линтерами"
	@echo "  make format     - Отформатировать код"

install:
	pip install -r requirements.txt

dev:
	uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

up:
	docker-compose up -d

down:
	docker-compose down

migrate:
	@read -p "Введите название миграции: " name; \
	alembic revision --autogenerate -m "$$name"

upgrade:
	alembic upgrade head

downgrade:
	alembic downgrade -1

test:
	pytest

lint:
	flake8 app/
	mypy app/

format:
	black app/
	isort app/

