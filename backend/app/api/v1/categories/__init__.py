"""Categories API."""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from pydantic import BaseModel
from typing import List
from datetime import datetime
import uuid

from app.database import get_db
from app.services.category_service import CategoryService
from app.services.business_service import BusinessService
from app.core.cache import cache_service, get_cache_key_categories

router = APIRouter()


class CategoryResponse(BaseModel):
    """Ответ с информацией о категории."""

    id: uuid.UUID
    name: str
    position: int
    surcharge: float = 0.0  # Доплата за категорию
    created_at: datetime | None = None
    updated_at: datetime | None = None


@router.get("/{business_slug}/categories", response_model=List[CategoryResponse])
async def get_categories(
    business_slug: str,
    db: AsyncSession = Depends(get_db),
):
    """
    Получить список категорий бизнеса.
    """
    # Проверяем кэш
    cache_key = get_cache_key_categories(business_slug)
    cached = await cache_service.get(cache_key)
    if cached:
        return [CategoryResponse(**item) for item in cached]

    service = CategoryService(db)
    categories = await service.get_by_business_slug(business_slug)

    result = [
        CategoryResponse(
            id=category.id,
            name=category.name,
            position=category.position,
            surcharge=float(category.surcharge),
            created_at=category.created_at,
            updated_at=category.updated_at,
        )
        for category in categories
    ]

    # Сохраняем в кэш (TTL 60 секунд)
    await cache_service.set(cache_key, [item.dict() for item in result], ttl=60)

    return result


class CreateCategoryRequest(BaseModel):
    """Запрос на создание категории."""

    name: str
    position: int = 0
    surcharge: float = 0.0  # Доплата за категорию


@router.post("/{business_slug}/categories", response_model=CategoryResponse, status_code=status.HTTP_201_CREATED)
async def create_category(
    business_slug: str,
    request: CreateCategoryRequest,
    db: AsyncSession = Depends(get_db),
):
    """
    Создать новую категорию для бизнеса.
    
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

    # Создаем категорию
    from decimal import Decimal
    category_service = CategoryService(db)
    category = await category_service.create(
        business_id=business.id,
        name=request.name,
        position=request.position,
        surcharge=Decimal(str(request.surcharge)),
    )

    # Очищаем кэш для этого бизнеса
    await cache_service.delete(get_cache_key_categories(business_slug))

    return CategoryResponse(
        id=category.id,
        name=category.name,
        position=category.position,
        surcharge=float(category.surcharge),
        created_at=category.created_at,
        updated_at=category.updated_at,
    )


class UpdateCategoryRequest(BaseModel):
    """Запрос на обновление категории."""
    name: str | None = None
    position: int | None = None
    surcharge: float | None = None  # Доплата за категорию


@router.put("/{category_id}", response_model=CategoryResponse)
@router.patch("/{category_id}", response_model=CategoryResponse)
async def update_category(
    category_id: uuid.UUID,
    request: UpdateCategoryRequest,
    db: AsyncSession = Depends(get_db),
):
    """
    Обновить категорию.
    
    ⚠️ ВНИМАНИЕ: В production здесь должна быть проверка авторизации!
    """
    from decimal import Decimal
    service = CategoryService(db)
    surcharge_decimal = Decimal(str(request.surcharge)) if request.surcharge is not None else None
    category = await service.update(
        category_id=category_id,
        name=request.name,
        position=request.position,
        surcharge=surcharge_decimal,
    )

    if not category:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Категория не найдена")

    # Очищаем кэш
    # Нужно найти business_slug для очистки кэша
    from app.models.business import Business
    from sqlalchemy import select
    stmt = select(Business).where(Business.id == category.business_id)
    result = await db.execute(stmt)
    business = result.scalar_one()
    await cache_service.delete(get_cache_key_categories(business.slug))

    return CategoryResponse(
        id=category.id,
        name=category.name,
        position=category.position,
        surcharge=float(category.surcharge),
        created_at=category.created_at,
        updated_at=category.updated_at,
    )


@router.delete("/{category_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_category(
    category_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
):
    """
    Удалить категорию.
    
    ⚠️ ВНИМАНИЕ: В production здесь должна быть проверка авторизации!
    """
    service = CategoryService(db)
    
    # Получаем категорию перед удалением для очистки кэша
    category = await service.get_by_id(category_id)
    if not category:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Категория не найдена")
    
    # Получаем business_slug для очистки кэша
    from app.models.business import Business
    from sqlalchemy import select
    stmt = select(Business).where(Business.id == category.business_id)
    result = await db.execute(stmt)
    business = result.scalar_one()
    
    success = await service.delete(category_id)
    if not success:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Категория не найдена")

    # Очищаем кэш
    await cache_service.delete(get_cache_key_categories(business.slug))

    return None

