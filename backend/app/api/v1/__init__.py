"""API v1 роутеры."""
from fastapi import APIRouter

from app.api.v1 import admin, telegram, businesses, products, orders, categories, payments, images, delivery, addresses, promocodes, loyalty, analytics

router = APIRouter()

# Подключаем все роутеры
router.include_router(admin.router, prefix="/admin", tags=["admin"])
router.include_router(telegram.router, prefix="/telegram", tags=["telegram"])
router.include_router(businesses.router, prefix="/businesses", tags=["businesses"])
router.include_router(products.router, prefix="/products", tags=["products"])
router.include_router(orders.router, prefix="/orders", tags=["orders"])
router.include_router(categories.router, prefix="/categories", tags=["categories"])
router.include_router(payments.router, prefix="/payments", tags=["payments"])
router.include_router(images.router, prefix="/images", tags=["images"])
router.include_router(delivery.router, prefix="/delivery", tags=["delivery"])
router.include_router(addresses.router, prefix="/addresses", tags=["addresses"])
router.include_router(promocodes.router, tags=["promocodes"])
router.include_router(loyalty.router, tags=["loyalty"])
router.include_router(analytics.router, tags=["analytics"])

