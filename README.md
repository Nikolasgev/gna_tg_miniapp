# GNA Telegram Store

Монорепозиторий: backend (FastAPI), Flutter Mini App и админ-панель, маркетинговый лендинг, документация и скрипты для отладки в Telegram.

## Структура

| Путь | Описание |
|------|----------|
| [`backend/`](backend/) | API: заказы, Telegram WebApp, платежи, лояльность, админ JWT. Запуск: `uvicorn app.main:app` из каталога `backend`. |
| [`frontend/`](frontend/) | Flutter Web: `lib/mini_app/` — Mini App, `lib/admin_panel/` — админка. |
| [`landing/`](landing/) | Маркетинг (Vite + React). Сборка: `npm run build` → `landing/dist/`. |
| [`docs/`](docs/) | Пояснительная записка, скрипт сборки DOCX. |
| [`presentation/`](presentation/) | HTML-слайды предзащиты (Reveal.js). |
| [`presentation_diagrams/`](presentation_diagrams/) | Исходники Mermaid для диаграмм. |
| Корневые `*.md` | Деплой, Telegram, тесты. |
| `start_for_telegram*.sh` | Скрипты HTTPS-туннелей для локальной отладки Mini App (см. ниже и [QUICK_TELEGRAM_SETUP.md](QUICK_TELEGRAM_SETUP.md)). |

## Backend

```bash
cd backend
python3 -m venv venv && source venv/bin/activate   # Windows: venv\Scripts\activate
pip install -r requirements.txt
# Укажите DATABASE_URL в .env, затем:
alembic upgrade head
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Тесты:

```bash
cd backend && source venv/bin/activate && python -m pytest tests/ -q
```

## Frontend (Mini App / Admin)

```bash
cd frontend
flutter pub get
flutter build web --release --target lib/mini_app/main.dart \
  --dart-define=API_BASE_URL=https://your-api.example.com
```

Unit-тесты (пример):

```bash
cd frontend && flutter test test/auth_bloc_test.dart
```

## Лендинг

```bash
cd landing
npm install
npm run dev
```

Секреты EmailJS (опционально): скопируйте [`landing/.env.example`](landing/.env.example) в `landing/.env` и задайте `VITE_EMAILJS_PUBLIC_KEY`.

## CI

В [`.github/workflows/ci.yml`](.github/workflows/ci.yml): тесты backend (`pytest`), при необходимости раскомментируйте шаги Flutter.

## Деплой и переменные окружения

- [DEPLOY_STEPS.md](DEPLOY_STEPS.md) — пошаговый деплой.
- В production задайте сильные `SECRET_KEY`, `ADMIN_PASSWORD` и явный список `CORS_ORIGINS` (см. `backend/app/config.py`).

## Скрипты туннелей (корень репозитория)

| Скрипт | Назначение |
|--------|------------|
| `start_for_telegram.sh` | Типичный сценарий с ngrok (см. QUICK_TELEGRAM_SETUP). |
| `start_for_telegram_ngrok.sh` | Один туннель ngrok на backend. |
| `start_for_telegram_single.sh` | Один туннель, если обычный ngrok недоступен. |
| `start_for_telegram_serveo.sh` | Альтернатива через Serveo (SSH). |
| `start_for_telegram_localhostrun.sh` | Альтернатива через localhost.run. |

Подробнее: [QUICK_TELEGRAM_SETUP.md](QUICK_TELEGRAM_SETUP.md).

## Git: вложенные репозитории

Если в `backend/` или `frontend/` есть каталог `.git`, корневой Git не версионирует их файлы как обычный код. **Принятое решение:** целевой вариант — **один монорепозиторий**; альтернатива — **submodules**. Пошаговые команды и сравнение: [`docs/MONOREPO.md`](docs/MONOREPO.md).

## Документация по Telegram

- [QUICK_TELEGRAM_SETUP.md](QUICK_TELEGRAM_SETUP.md)
- [TELEGRAM_BOT_SETUP.md](TELEGRAM_BOT_SETUP.md)
