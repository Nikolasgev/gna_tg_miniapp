.PHONY: help install dev up down start stop migrate upgrade downgrade test lint format

help:
	@echo "Доступные команды:"
	@echo "  make install    - Установить зависимости"
	@echo "  make start      - Запустить всё (БД, Redis, бэкенд)"
	@echo "  make stop       - Остановить всё"
	@echo "  make dev        - Запустить только бэкенд (без Docker)"
	@echo "  make up         - Запустить Docker Compose (БД и Redis)"
	@echo "  make down       - Остановить Docker Compose"
	@echo "  make migrate    - Создать новую миграцию"
	@echo "  make upgrade    - Применить миграции"
	@echo "  make downgrade  - Откатить миграцию"
	@echo "  make test       - Запустить тесты"
	@echo "  make lint       - Проверить код линтерами"
	@echo "  make format     - Отформатировать код"

install:
	pip install -r requirements.txt

start: up wait-db upgrade
	@echo "✅ Все сервисы запущены!"
	@echo "📦 База данных: PostgreSQL на порту 5432"
	@echo "🔴 Redis: на порту 6379"
	@echo "🚀 Запускаю бэкенд сервер..."
	@./venv/bin/uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

stop: down
	@echo "✅ Все сервисы остановлены"

dev:
	./venv/bin/uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

up:
	@echo "🐳 Запускаю Docker Compose (PostgreSQL и Redis)..."
	@docker-compose up -d
	@echo "⏳ Ожидаю готовности сервисов..."

wait-db:
	@echo "⏳ Ожидаю готовности PostgreSQL..."
	@timeout=30; \
	while [ $$timeout -gt 0 ]; do \
		if docker-compose exec -T postgres pg_isready -U postgres > /dev/null 2>&1; then \
			echo "✅ PostgreSQL готов!"; \
			break; \
		fi; \
		echo "   Ожидание... (осталось $$timeout сек)"; \
		sleep 1; \
		timeout=$$((timeout - 1)); \
	done; \
	if [ $$timeout -eq 0 ]; then \
		echo "❌ PostgreSQL не запустился за 30 секунд"; \
		exit 1; \
	fi
	@echo "⏳ Ожидаю готовности Redis..."
	@timeout=30; \
	while [ $$timeout -gt 0 ]; do \
		if docker-compose exec -T redis redis-cli ping > /dev/null 2>&1; then \
			echo "✅ Redis готов!"; \
			break; \
		fi; \
		echo "   Ожидание... (осталось $$timeout сек)"; \
		sleep 1; \
		timeout=$$((timeout - 1)); \
	done; \
	if [ $$timeout -eq 0 ]; then \
		echo "❌ Redis не запустился за 30 секунд"; \
		exit 1; \
	fi

down:
	docker-compose down

migrate:
	@read -p "Введите название миграции: " name; \
	./venv/bin/alembic revision --autogenerate -m "$$name"

upgrade:
	./venv/bin/alembic upgrade head

downgrade:
	./venv/bin/alembic downgrade -1

test:
	pytest

lint:
	flake8 app/
	mypy app/

format:
	black app/
	isort app/

