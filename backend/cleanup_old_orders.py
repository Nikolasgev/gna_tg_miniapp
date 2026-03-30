"""Скрипт для ручного запуска удаления старых заказов."""
import asyncio
import logging
from app.database import AsyncSessionLocal
from app.services.order_service import OrderService

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


async def main():
    """Удалить старые заказы."""
    try:
        async with AsyncSessionLocal() as db:
            order_service = OrderService(db)
            deleted_count = await order_service.delete_old_orders(days=7)
            logger.info(f"Удалено {deleted_count} старых заказов (статус: cancelled/completed, старше 7 дней)")
    except Exception as e:
        logger.error(f"Ошибка при удалении старых заказов: {e}", exc_info=True)
        raise


if __name__ == "__main__":
    asyncio.run(main())

