# Второй сервис Railway: polling-бот (опционально)

API уже может вызывать Bot API (`sendMessage`, валидация WebApp), если задан `TELEGRAM_BOT_TOKEN`. Отдельный процесс нужен для ответов на `/start`, `/help` и текст в ЛС ([backend/app/bot/main.py](../backend/app/bot/main.py)).

## Вариант: второй сервис в том же проекте Railway

1. В Railway: **New** → **Empty Service** (или **GitHub Repo** → тот же репозиторий `gna_tg_miniapp`, что и у API).
2. **Settings** → тот же **Root Directory** / Dockerfile, что у backend (корень `backend` в монорепо или корень репо бэка).
3. **Settings** → **Deploy** → **Custom Start Command**:
   ```bash
   python run_telegram_bot.py
   ```
4. **Variables** — скопировать из сервиса API как минимум:
   - `TELEGRAM_BOT_TOKEN` (обязательно)
   - при необходимости те же `DATABASE_URL` / прочие, если позже расширите бота

5. Для сервиса **без HTTP** в Railway можно отключить публичный домен или оставить — процесс только polling, порт не обязателен.

## Локальный запуск

```bash
cd backend
source venv/bin/activate
export TELEGRAM_BOT_TOKEN="ваш_токен"
python run_telegram_bot.py
```

## Один токен — два процесса

И API, и polling-бот используют один `TELEGRAM_BOT_TOKEN`. Это нормально для Bot API.
