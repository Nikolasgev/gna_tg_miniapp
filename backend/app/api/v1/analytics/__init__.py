"""Analytics API."""
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, and_, case, Date, cast
from sqlalchemy.orm import selectinload
from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime, timedelta
from decimal import Decimal
import uuid

from app.database import get_db
from app.models.order import Order, OrderItem
from app.models.product import Product
from app.models.promocode import Promocode, PromocodeUsage

router = APIRouter()


class AnalyticsSummaryResponse(BaseModel):
    """Сводная статистика."""
    
    total_revenue: float
    total_orders: int
    avg_order_value: float
    total_discounts: float
    promocode_usage_count: int
    top_products: List[dict]
    orders_by_status: dict
    orders_by_payment_status: dict
    revenue_by_period: List[dict]  # [{date: str, revenue: float, orders: int}]


@router.get("/businesses/{business_id}/analytics/summary", response_model=AnalyticsSummaryResponse)
async def get_analytics_summary(
    business_id: uuid.UUID,
    start_date: Optional[str] = Query(None, description="Начальная дата (YYYY-MM-DD)"),
    end_date: Optional[str] = Query(None, description="Конечная дата (YYYY-MM-DD)"),
    db: AsyncSession = Depends(get_db),
):
    """
    Получить сводную аналитику по бизнесу.
    
    Возвращает общую статистику по заказам, выручке, промокодам и популярным товарам.
    """
    try:
        # Парсим даты
        start = None
        end = None
        if start_date:
            try:
                start = datetime.fromisoformat(start_date.replace('Z', '+00:00'))
            except ValueError:
                start = datetime.strptime(start_date, '%Y-%m-%d')
        if end_date:
            try:
                end = datetime.fromisoformat(end_date.replace('Z', '+00:00'))
            except ValueError:
                end = datetime.strptime(end_date, '%Y-%m-%d')
            # Устанавливаем конец дня
            end = end.replace(hour=23, minute=59, second=59)
        else:
            end = datetime.utcnow()
        if not start:
            start = end - timedelta(days=30)  # По умолчанию последние 30 дней
        
        # Базовое условие для фильтрации - только оплаченные заказы
        date_filter = and_(
            Order.business_id == business_id,
            Order.created_at >= start,
            Order.created_at <= end,
            Order.payment_status == 'paid',  # Только оплаченные заказы
        )
        
        # Общая выручка
        revenue_stmt = select(
            func.coalesce(func.sum(Order.total_amount), 0).label('total_revenue'),
            func.count(Order.id).label('total_orders'),
            func.sum(Order.discount_amount).label('total_discounts'),
        ).where(date_filter)
        revenue_result = await db.execute(revenue_stmt)
        revenue_row = revenue_result.first()
        
        total_revenue = float(revenue_row.total_revenue or 0)
        total_orders = revenue_row.total_orders or 0
        total_discounts = float(revenue_row.total_discounts or 0)
        avg_order_value = total_revenue / total_orders if total_orders > 0 else 0
        
        # Статистика по промокодам
        promocode_stmt = select(
            func.count(PromocodeUsage.id).label('usage_count')
        ).join(Order, PromocodeUsage.order_id == Order.id).where(date_filter)
        promocode_result = await db.execute(promocode_stmt)
        promocode_usage_count = promocode_result.scalar() or 0
        
        # Топ товаров по количеству продаж
        top_products_stmt = select(
            Product.id,
            Product.title,
            func.sum(OrderItem.quantity).label('total_quantity'),
            func.sum(OrderItem.total_price).label('total_revenue'),
        ).join(
            OrderItem, OrderItem.product_id == Product.id
        ).join(
            Order, Order.id == OrderItem.order_id
        ).where(
            date_filter
        ).group_by(
            Product.id, Product.title
        ).order_by(
            func.sum(OrderItem.quantity).desc()
        ).limit(10)
        
        top_products_result = await db.execute(top_products_stmt)
        top_products = [
            {
                'id': str(row.id),
                'title': row.title,
                'quantity': int(row.total_quantity or 0),
                'revenue': float(row.total_revenue or 0),
            }
            for row in top_products_result.all()
        ]
        
        # Заказы по статусам
        orders_by_status_stmt = select(
            Order.status,
            func.count(Order.id).label('count')
        ).where(date_filter).group_by(Order.status)
        orders_by_status_result = await db.execute(orders_by_status_stmt)
        orders_by_status = {
            row.status: row.count
            for row in orders_by_status_result.all()
        }
        
        # Заказы по статусу оплаты
        orders_by_payment_status_stmt = select(
            Order.payment_status,
            func.count(Order.id).label('count')
        ).where(date_filter).group_by(Order.payment_status)
        orders_by_payment_status_result = await db.execute(orders_by_payment_status_stmt)
        orders_by_payment_status = {
            row.payment_status: row.count
            for row in orders_by_payment_status_result.all()
        }
        
        # Выручка по периодам (последние 7 дней)
        period_start = end - timedelta(days=7)
        # Используем cast для извлечения даты (работает на PostgreSQL и SQLite)
        revenue_by_period_stmt = select(
            cast(Order.created_at, Date).label('date'),
            func.sum(Order.total_amount).label('revenue'),
            func.count(Order.id).label('orders'),
        ).where(
            and_(
                date_filter,
                Order.created_at >= period_start,
            )
        ).group_by(
            cast(Order.created_at, Date)
        ).order_by(
            cast(Order.created_at, Date)
        )
        
        revenue_by_period_result = await db.execute(revenue_by_period_stmt)
        revenue_by_period = [
            {
                'date': row.date.isoformat() if row.date else '',
                'revenue': float(row.revenue or 0),
                'orders': row.orders or 0,
            }
            for row in revenue_by_period_result.all()
        ]
        
        return AnalyticsSummaryResponse(
            total_revenue=total_revenue,
            total_orders=total_orders,
            avg_order_value=avg_order_value,
            total_discounts=total_discounts,
            promocode_usage_count=promocode_usage_count,
            top_products=top_products,
            orders_by_status=orders_by_status,
            orders_by_payment_status=orders_by_payment_status,
            revenue_by_period=revenue_by_period,
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Ошибка при получении аналитики: {str(e)}",
        )

