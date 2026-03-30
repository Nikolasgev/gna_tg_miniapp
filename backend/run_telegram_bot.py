"""Запуск обработчика бота (polling). Отдельный процесс от uvicorn / gunicorn."""

from app.bot.main import run_bot

if __name__ == "__main__":
    run_bot()
