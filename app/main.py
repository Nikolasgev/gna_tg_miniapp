"""Главный файл приложения."""
import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from apscheduler.schedulers.asyncio import AsyncIOScheduler
from apscheduler.triggers.cron import CronTrigger

from app.config import settings
from app.api.v1 import router as api_v1_router
from app.database import AsyncSessionLocal
from app.services.order_service import OrderService

# Настройка логирования
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Глобальный планировщик задач
scheduler = AsyncIOScheduler()


async def cleanup_old_orders():
    """Периодическая задача для удаления старых заказов."""
    try:
        async with AsyncSessionLocal() as db:
            order_service = OrderService(db)
            deleted_count = await order_service.delete_old_orders(days=7)
            if deleted_count > 0:
                logger.info(f"Удалено {deleted_count} старых заказов (статус: cancelled/completed, старше 7 дней)")
    except Exception as e:
        logger.error(f"Ошибка при удалении старых заказов: {e}", exc_info=True)


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Управление жизненным циклом приложения."""
    # Startup
    from app.core.cache import cache_service
    await cache_service.connect()
    
    # Запускаем планировщик задач
    # Задача будет выполняться каждый день в 3:00 UTC
    scheduler.add_job(
        cleanup_old_orders,
        trigger=CronTrigger(hour=3, minute=0),
        id="cleanup_old_orders",
        name="Удаление старых заказов",
        replace_existing=True,
    )
    scheduler.start()
    logger.info("Планировщик задач запущен. Задача удаления старых заказов запланирована на 3:00 UTC ежедневно")
    
    yield
    
    # Shutdown
    scheduler.shutdown(wait=False)
    await cache_service.disconnect()


app = FastAPI(
    title="Telegram Mini App Builder API",
    description="Backend API для конструктора Telegram Mini App",
    version="1.0.0",
    lifespan=lifespan,
)

# CORS - в development режиме разрешаем ВСЕ origins для тестирования
# ⚠️ ВНИМАНИЕ: Это только для разработки! В production нужно строго ограничить origins!
if settings.is_development:
    # Разрешаем все origins для удобства тестирования
    cors_origins = ["*"]
    # Нельзя использовать allow_credentials=True с allow_origins=["*"]
    allow_creds = False
else:
    cors_origins = list(set(settings.cors_origins))
    allow_creds = True

app.add_middleware(
    CORSMiddleware,
    allow_origins=cors_origins,
    allow_credentials=allow_creds,
    allow_methods=["GET", "POST", "PUT", "DELETE", "OPTIONS", "PATCH"],
    allow_headers=["*"],
    expose_headers=["*"],
)

# Подключаем роутеры
app.include_router(api_v1_router, prefix="/api/v1")

# Статическая раздача загруженных изображений
# ВАЖНО: mount должен быть ПОСЛЕ подключения роутеров, чтобы роутер /api/v1/images/uploads/{filename} имел приоритет
# StaticFiles будет использоваться только для прямого доступа к файлам, если роутер не обработал запрос
import os
import logging
from pathlib import Path

logger = logging.getLogger(__name__)

# Используем абсолютный путь относительно корня проекта (backend/)
# __file__ = backend/app/main.py
# parent.parent = backend/
BASE_DIR = Path(__file__).resolve().parent.parent
upload_dir = BASE_DIR / "uploads" / "images"
upload_dir.mkdir(parents=True, exist_ok=True)

logger.info(f"Static files mount: {upload_dir}, exists: {upload_dir.exists()}")

# НЕ монтируем StaticFiles, так как у нас есть роутер для обработки запросов
# app.mount("/api/v1/images/uploads", StaticFiles(directory=str(upload_dir)), name="uploads")


@app.get("/")
async def root():
    """Корневой endpoint."""
    return {
        "message": "Telegram Mini App Builder API",
        "version": "1.0.0",
        "docs": "/docs",
    }


@app.get("/health")
async def health():
    """Health check endpoint."""
    return {"status": "ok"}

