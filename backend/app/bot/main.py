"""Точка входа бота: long polling, команды /start и каркас поддержки."""
from __future__ import annotations

import logging

from telegram import Update
from telegram.ext import Application, CommandHandler, ContextTypes, MessageHandler, filters

from app.config import settings

logger = logging.getLogger(__name__)


async def cmd_start(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    if update.message:
        await update.message.reply_text(
            "Привет! Я бот магазина. Откройте Mini App кнопкой в меню "
            "или напишите сообщение для поддержки."
        )


async def cmd_help(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    if update.message:
        await update.message.reply_text(
            "Поддержка: опишите вопрос одним сообщением. "
            "Дальше можно подключить пересылку в админку или тикет-систему."
        )


async def support_text(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    if update.message and update.message.text:
        await update.message.reply_text(
            "Сообщение получено. Здесь можно логировать обращение или пересылать оператору."
        )


def run_bot() -> None:
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
    )
    token = (settings.telegram_bot_token or "").strip()
    if not token:
        raise SystemExit(
            "TELEGRAM_BOT_TOKEN не задан. Укажите токен бота в переменных окружения."
        )
    application = Application.builder().token(token).build()
    application.add_handler(CommandHandler("start", cmd_start))
    application.add_handler(CommandHandler("help", cmd_help))
    application.add_handler(MessageHandler(filters.TEXT & ~filters.COMMAND, support_text))
    logger.info("Запуск Telegram-бота (polling)")
    application.run_polling(allowed_updates=Update.ALL_TYPES)


if __name__ == "__main__":
    run_bot()
