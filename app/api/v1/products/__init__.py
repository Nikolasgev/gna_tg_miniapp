"""Products API."""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.exc import IntegrityError
from pydantic import BaseModel
from typing import List
from decimal import Decimal
from datetime import datetime
from urllib.parse import urlparse
import uuid

from app.database import get_db
from app.core.cache import cache_service, get_cache_key_products
from app.services.product_service import ProductService
from app.services.business_service import BusinessService

router = APIRouter()


def normalize_image_url(image_url: str | None) -> str | None:
    """Нормализует image_url: для загруженных файлов возвращает относительный путь."""
    if not image_url:
        return None
    # Если это полный URL с путем к загруженным файлам, извлекаем относительный путь
    if '/api/v1/images/uploads/' in image_url:
        # Извлекаем путь после домена
        parsed = urlparse(image_url)
        return parsed.path  # Возвращаем /api/v1/images/uploads/filename.png
    # Если это уже относительный путь, возвращаем как есть
    if image_url.startswith('/'):
        return image_url
    # Для внешних URL возвращаем как есть
    return image_url


class ProductResponse(BaseModel):
    """Ответ с информацией о продукте."""

    id: uuid.UUID
    title: str
    description: str | None = None
    price: float
    currency: str
    image_url: str | None = None
    variations: dict | None = None  # Вариации товара (размер, цвет и т.д.)
    is_active: bool
    category_ids: List[uuid.UUID] = []
    # Поля для скидок
    discount_percentage: float | None = None  # Процент скидки (0-100)
    discount_price: float | None = None  # Цена со скидкой
    discount_valid_from: str | None = None  # Дата начала действия скидки (ISO format)
    discount_valid_until: str | None = None  # Дата окончания действия скидки (ISO format)
    # Управление складом
    stock_quantity: int | None = None  # Количество товара на складе (None = неограниченно)


@router.get("/{business_slug}/products", response_model=List[ProductResponse])
async def get_products(
    business_slug: str,
    category: uuid.UUID | None = None,
    q: str | None = None,
    min_price: float | None = None,
    max_price: float | None = None,
    page: int = 1,
    limit: int = 20,
    include_inactive: bool = False,  # Для админки можно запросить все товары
    db: AsyncSession = Depends(get_db),
):
    """
    Получить список продуктов бизнеса.

    Параметры:
    - category: фильтр по категории
    - q: поисковый запрос
    - page: номер страницы
    - limit: количество элементов на странице
    """
    # Преобразуем min_price и max_price в Decimal для сервиса
    from decimal import Decimal
    min_price_decimal = Decimal(str(min_price)) if min_price is not None else None
    max_price_decimal = Decimal(str(max_price)) if max_price is not None else None

    # Кеширование только для публичных запросов (не для админки)
    cache_key = None
    if not include_inactive:
        cache_key = get_cache_key_products(
            business_slug,
            str(category) if category else None,
            q,
            str(min_price) if min_price else None,
            str(max_price) if max_price else None,
            page,
            limit,
        )
        # Пытаемся получить из кеша
        cached_result = await cache_service.get(cache_key)
        if cached_result is not None:
            return [ProductResponse(**item) for item in cached_result]

    from app.services.product_service import ProductService

    service = ProductService(db)
    products = await service.get_by_business_slug(
        business_slug=business_slug,
        category_id=category,
        search_query=q,
        min_price=min_price_decimal,
        max_price=max_price_decimal,
        page=page,
        limit=limit,
        include_inactive=include_inactive,
    )

    result = [
        ProductResponse(
            id=product.id,
            title=product.title,
            description=product.description,
            price=float(product.price),
            currency=product.currency,
            image_url=normalize_image_url(product.image_url),
            variations=product.variations,
            is_active=product.is_active,
            category_ids=[cat.id for cat in product.categories],
            discount_percentage=float(product.discount_percentage) if product.discount_percentage else None,
            discount_price=float(product.discount_price) if product.discount_price else None,
            discount_valid_from=product.discount_valid_from.isoformat() if product.discount_valid_from else None,
            discount_valid_until=product.discount_valid_until.isoformat() if product.discount_valid_until else None,
            stock_quantity=product.stock_quantity,
        )
        for product in products
    ]

    # Сохраняем в кеш только для публичных запросов (TTL 5 минут)
    if cache_key:
        await cache_service.set(cache_key, [item.model_dump() for item in result], ttl=300)

    return result


@router.get("/{product_id}", response_model=ProductResponse)
async def get_product(
    product_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
):
    """
    Получить продукт по ID.
    """
    service = ProductService(db)
    product = await service.get_by_id(product_id)

    if not product:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Продукт с ID '{product_id}' не найден",
        )

    # Загружаем категории через selectinload
    from sqlalchemy.orm import selectinload
    from sqlalchemy import select
    from app.models.product import Product

    stmt = select(Product).options(selectinload(Product.categories)).where(Product.id == product_id)
    result = await db.execute(stmt)
    product_with_categories = result.scalar_one()

    return ProductResponse(
        id=product_with_categories.id,
        title=product_with_categories.title,
        description=product_with_categories.description,
        price=float(product_with_categories.price),
        currency=product_with_categories.currency,
        image_url=normalize_image_url(product_with_categories.image_url),
        variations=product_with_categories.variations,
        is_active=product_with_categories.is_active,
        category_ids=[cat.id for cat in product_with_categories.categories],
        discount_percentage=float(product_with_categories.discount_percentage) if product_with_categories.discount_percentage else None,
        discount_price=float(product_with_categories.discount_price) if product_with_categories.discount_price else None,
        discount_valid_from=product_with_categories.discount_valid_from.isoformat() if product_with_categories.discount_valid_from else None,
        discount_valid_until=product_with_categories.discount_valid_until.isoformat() if product_with_categories.discount_valid_until else None,
        stock_quantity=product_with_categories.stock_quantity,
    )


class CreateProductRequest(BaseModel):
    """Запрос на создание продукта."""

    title: str
    description: str | None = None
    price: Decimal
    currency: str = "RUB"
    sku: str | None = None
    image_url: str | None = None
    variations: dict | None = None  # Вариации товара (размер, цвет и т.д.)
    is_active: bool = True
    category_ids: List[uuid.UUID] = []
    # Поля для скидок
    discount_percentage: Decimal | None = None  # Процент скидки (0-100)
    discount_price: Decimal | None = None  # Цена со скидкой
    discount_valid_from: datetime | None = None  # Дата начала действия скидки
    discount_valid_until: datetime | None = None  # Дата окончания действия скидки
    # Управление складом
    stock_quantity: int | None = None  # Количество товара на складе (None = неограниченно)


@router.post("/{business_slug}/products", response_model=ProductResponse, status_code=status.HTTP_201_CREATED)
async def create_product(
    business_slug: str,
    request: CreateProductRequest,
    db: AsyncSession = Depends(get_db),
):
    """
    Создать новый продукт для бизнеса.
    
    ⚠️ ВНИМАНИЕ: В production здесь должна быть проверка авторизации!
    """
    # Находим бизнес
    business_service = BusinessService(db)
    business = await business_service.get_by_slug(business_slug)
    
    if not business:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Бизнес с slug '{business_slug}' не найден",
        )

    # Создаем продукт
    product_service = ProductService(db)
    
    # Сохраняем category_ids до создания продукта
    category_ids = request.category_ids if request.category_ids else []
    
    # Создаем продукт - теперь возвращает только ID
    product_id = await product_service.create(
        business_id=business.id,
        title=request.title,
        description=request.description,
        price=request.price,
        currency=request.currency,
        sku=request.sku,
        image_url=request.image_url,
        variations=request.variations,
        is_active=request.is_active,
        category_ids=category_ids,
        discount_percentage=request.discount_percentage,
        discount_price=request.discount_price,
        discount_valid_from=request.discount_valid_from,
        discount_valid_until=request.discount_valid_until,
        stock_quantity=request.stock_quantity,
    )

    # Очищаем кэш для продуктов этого бизнеса
    from app.core.cache import cache_service, get_cache_key_products
    await cache_service.delete_pattern(get_cache_key_products(business_slug, "*"))

    # Используем значения из request для ответа, чтобы избежать проблем с lazy loading
    return ProductResponse(
        id=product_id,
        title=request.title,
        description=request.description,
        price=float(request.price),
        currency=request.currency,
        image_url=request.image_url,
        variations=request.variations,
        is_active=request.is_active,
        category_ids=category_ids,
        discount_percentage=float(request.discount_percentage) if request.discount_percentage else None,
        discount_price=float(request.discount_price) if request.discount_price else None,
        discount_valid_from=request.discount_valid_from.isoformat() if request.discount_valid_from else None,
        discount_valid_until=request.discount_valid_until.isoformat() if request.discount_valid_until else None,
        stock_quantity=request.stock_quantity,
    )


class UpdateProductRequest(BaseModel):
    """Запрос на обновление продукта."""
    title: str | None = None
    description: str | None = None
    price: Decimal | None = None
    currency: str | None = None
    sku: str | None = None
    image_url: str | None = None
    variations: dict | None = None  # Вариации товара (размер, цвет и т.д.)
    is_active: bool | None = None
    category_ids: List[uuid.UUID] | None = None
    # Поля для скидок
    discount_percentage: Decimal | None = None  # Процент скидки (0-100)
    discount_price: Decimal | None = None  # Цена со скидкой
    discount_valid_from: datetime | None = None  # Дата начала действия скидки
    discount_valid_until: datetime | None = None  # Дата окончания действия скидки
    # Управление складом
    stock_quantity: int | None = None  # Количество товара на складе (None = неограниченно)


@router.put("/{product_id}", response_model=ProductResponse)
@router.patch("/{product_id}", response_model=ProductResponse)
async def update_product(
    product_id: uuid.UUID,
    request: UpdateProductRequest,
    db: AsyncSession = Depends(get_db),
):
    """
    Обновить продукт.
    
    ⚠️ ВНИМАНИЕ: В production здесь должна быть проверка авторизации!
    """
    service = ProductService(db)
    
    # Преобразуем Decimal в Decimal для price
    price_decimal = None
    if request.price is not None:
        price_decimal = request.price

    product = await service.update(
        product_id=product_id,
        title=request.title,
        description=request.description,
        price=price_decimal,
        currency=request.currency,
        sku=request.sku,
        image_url=request.image_url,
        variations=request.variations,
        is_active=request.is_active,
        category_ids=request.category_ids,
        discount_percentage=request.discount_percentage,
        discount_price=request.discount_price,
        discount_valid_from=request.discount_valid_from,
        discount_valid_until=request.discount_valid_until,
        stock_quantity=request.stock_quantity,
    )

    if not product:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Продукт с ID '{product_id}' не найден",
        )

    # Загружаем категории
    from sqlalchemy.orm import selectinload
    from sqlalchemy import select
    from app.models.product import Product

    stmt = select(Product).options(selectinload(Product.categories)).where(Product.id == product_id)
    result = await db.execute(stmt)
    product_with_categories = result.scalar_one()

    # Очищаем кэш для продуктов этого бизнеса
    # Получаем business_id для очистки кэша
    from app.models.business import Business
    stmt_business = select(Business).where(Business.id == product.business_id)
    result_business = await db.execute(stmt_business)
    business = result_business.scalar_one()
    
    # Очищаем кэш для продуктов этого бизнеса
    from app.core.cache import cache_service, get_cache_key_products
    await cache_service.delete_pattern(get_cache_key_products(business.slug, "*"))

    return ProductResponse(
        id=product_with_categories.id,
        title=product_with_categories.title,
        description=product_with_categories.description,
        price=float(product_with_categories.price),
        currency=product_with_categories.currency,
        image_url=normalize_image_url(product_with_categories.image_url),
        variations=product_with_categories.variations,
        is_active=product_with_categories.is_active,
        category_ids=[cat.id for cat in product_with_categories.categories],
        discount_percentage=float(product_with_categories.discount_percentage) if product_with_categories.discount_percentage else None,
        discount_price=float(product_with_categories.discount_price) if product_with_categories.discount_price else None,
        discount_valid_from=product_with_categories.discount_valid_from.isoformat() if product_with_categories.discount_valid_from else None,
        discount_valid_until=product_with_categories.discount_valid_until.isoformat() if product_with_categories.discount_valid_until else None,
        stock_quantity=product_with_categories.stock_quantity,
    )


@router.delete("/{product_id}")
async def delete_product(
    product_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
):
    """
    Удалить продукт.
    
    Если продукт используется в заказах, он будет деактивирован (мягкое удаление).
    Если продукт не используется в заказах, он будет физически удален.
    
    ⚠️ ВНИМАНИЕ: В production здесь должна быть проверка авторизации!
    """
    from pydantic import BaseModel
    
    class DeleteResponse(BaseModel):
        """Ответ при удалении продукта."""
        message: str
        deactivated: bool = False
    
    service = ProductService(db)
    
    # Получаем продукт перед удалением для очистки кэша
    product = await service.get_by_id(product_id)
    if not product:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Продукт с ID '{product_id}' не найден",
        )
    
    # Получаем business_slug для очистки кэша (сохраняем до обработки ошибок)
    from app.models.business import Business
    from sqlalchemy import select
    stmt = select(Business).where(Business.id == product.business_id)
    result = await db.execute(stmt)
    business = result.scalar_one()
    business_slug = business.slug  # Сохраняем slug до обработки ошибок
    
    # Пытаемся удалить продукт физически
    try:
        success = await service.delete(product_id)
        if not success:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Продукт с ID '{product_id}' не найден",
            )
        
        # Очищаем кэш для продуктов этого бизнеса
        from app.core.cache import cache_service, get_cache_key_products
        await cache_service.delete_pattern(get_cache_key_products(business_slug, "*"))
        
        return DeleteResponse(message="Товар успешно удален", deactivated=False)
        
    except IntegrityError as e:
        # Откатываем транзакцию после ошибки
        await db.rollback()
        
        # Проверяем, является ли это ошибкой foreign key constraint
        error_str = str(e.orig) if hasattr(e, 'orig') else str(e)
        
        # Если продукт используется в заказах, делаем мягкое удаление (деактивация)
        if ("foreign key" in error_str.lower() or 
            "order_items" in error_str.lower() or
            "ForeignKeyViolationError" in error_str):
            # Деактивируем продукт вместо физического удаления
            from app.models.product import Product
            from sqlalchemy import update
            stmt = update(Product).where(Product.id == product_id).values(is_active=False)
            await db.execute(stmt)
            await db.commit()
            
            # Очищаем кэш для продуктов этого бизнеса
            from app.core.cache import cache_service, get_cache_key_products
            await cache_service.delete_pattern(get_cache_key_products(business_slug, "*"))
            
            return DeleteResponse(
                message="Статус изменен на неактивен, но невозможно удалить, так как используется в заказе",
                deactivated=True
            )
        else:
            # Другая ошибка целостности - пробрасываем дальше
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Не удалось удалить продукт: {error_str}",
            )
    except Exception as e:
        # Откатываем транзакцию при любой другой ошибке
        await db.rollback()
        # Другая ошибка - пробрасываем дальше
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Ошибка при удалении продукта: {str(e)}",
        )
