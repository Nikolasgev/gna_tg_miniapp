"""Скрипт для удаления всех заказов из базы данных."""
import asyncio
import logging
from sqlalchemy import select, delete
from app.database import AsyncSessionLocal
from app.models.order import Order, OrderItem

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


async def delete_all_orders():
    """Удалить все заказы из базы данных."""
    try:
        async with AsyncSessionLocal() as db:
            # Получаем все заказы
            stmt = select(Order)
            result = await db.execute(stmt)
            orders = result.scalars().all()
            
            if not orders:
                logger.info("В базе данных нет заказов для удаления")
                return
            
            order_count = len(orders)
            logger.info(f"Найдено {order_count} заказов для удаления")
            
            # Получаем ID всех заказов
            order_ids = [order.id for order in orders]
            
            # Удаляем элементы заказов (order_items) сначала из-за внешнего ключа
            delete_items_stmt = delete(OrderItem).where(OrderItem.order_id.in_(order_ids))
            result = await db.execute(delete_items_stmt)
            deleted_items_count = result.rowcount
            logger.info(f"Удалено {deleted_items_count} элементов заказов")
            
            # Удаляем сами заказы
            delete_orders_stmt = delete(Order).where(Order.id.in_(order_ids))
            result = await db.execute(delete_orders_stmt)
            deleted_orders_count = result.rowcount
            
            await db.commit()
            
            logger.info(f"✅ Успешно удалено {deleted_orders_count} заказов и {deleted_items_count} элементов заказов")
            
    except Exception as e:
        logger.error(f"❌ Ошибка при удалении заказов: {e}", exc_info=True)
        raise


if __name__ == "__main__":
    # Запрашиваем подтверждение
    logger.warning("⚠️  ВНИМАНИЕ: Вы собираетесь удалить ВСЕ заказы из базы данных!")
    logger.warning("Это действие нельзя отменить.")
    confirmation = input("Введите 'DELETE ALL' для подтверждения: ")
    
    if confirmation == "DELETE ALL":
        asyncio.run(delete_all_orders())
    else:
        logger.info("❌ Операция отменена")

