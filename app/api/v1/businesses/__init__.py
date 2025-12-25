"""Businesses API."""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from pydantic import BaseModel
import uuid

from app.database import get_db
from app.services.business_service import BusinessService

router = APIRouter()


class BusinessResponse(BaseModel):
    """Ответ с информацией о бизнесе."""

    id: uuid.UUID
    name: str
    slug: str
    description: str | None = None


@router.get("/{slug}", response_model=BusinessResponse)
async def get_business(
    slug: str,
    db: AsyncSession = Depends(get_db),
):
    """
    Получить публичную информацию о бизнесе.
    """
    service = BusinessService(db)
    business = await service.get_by_slug(slug)

    if not business:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Бизнес с slug '{slug}' не найден",
        )

    return BusinessResponse(
        id=business.id,
        name=business.name,
        slug=business.slug,
        description=business.description,
    )


class CreateBusinessRequest(BaseModel):
    """Запрос на создание бизнеса."""

    name: str
    slug: str
    description: str | None = None
    owner_id: uuid.UUID | None = None  # Если не указан, создается дефолтный owner


@router.post("", response_model=BusinessResponse, status_code=status.HTTP_201_CREATED)
async def create_business(
    request: CreateBusinessRequest,
    db: AsyncSession = Depends(get_db),
):
    """
    Создать бизнес.

    ⚠️ ВНИМАНИЕ: В production здесь должна быть проверка авторизации!
    Для тестирования создает бизнес без проверки.
    """
    from app.models.user import User
    from sqlalchemy import select

    # Если owner_id не указан, создаем или находим дефолтного owner
    if request.owner_id:
        owner_id = request.owner_id
    else:
        # Ищем или создаем дефолтного owner
        stmt = select(User).where(User.role == "owner").limit(1)
        result = await db.execute(stmt)
        owner = result.scalar_one_or_none()

        if not owner:
            # Создаем дефолтного owner
            owner = User(
                role="owner",
                email="admin@example.com",
            )
            db.add(owner)
            await db.flush()
        owner_id = owner.id

    service = BusinessService(db)
    
    # Проверяем, не существует ли уже бизнес с таким slug
    existing = await service.get_by_slug(request.slug)
    if existing:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Бизнес с slug '{request.slug}' уже существует",
        )

    business = await service.create(
        owner_id=owner_id,
        name=request.name,
        slug=request.slug,
        description=request.description,
    )

    return BusinessResponse(
        id=business.id,
        name=business.name,
        slug=business.slug,
        description=business.description,
    )


class BusinessSettingsResponse(BaseModel):
    """Ответ с настройками бизнеса."""

    name: str
    slug: str
    description: str | None = None
    currency: str = "RUB"
    timezone: str | None = None
    logo: str | None = None
    primary_color: str | None = None
    background_color: str | None = None
    text_color: str | None = None
    # Дополнительные цвета темы
    secondary_color: str | None = None
    tertiary_color: str | None = None
    error_color: str | None = None
    surface_color: str | None = None
    on_primary_color: str | None = None
    on_secondary_color: str | None = None
    on_tertiary_color: str | None = None
    on_error_color: str | None = None
    on_surface_color: str | None = None
    primary_container_color: str | None = None
    secondary_container_color: str | None = None
    tertiary_container_color: str | None = None
    error_container_color: str | None = None
    on_primary_container_color: str | None = None
    on_secondary_container_color: str | None = None
    on_tertiary_container_color: str | None = None
    on_error_container_color: str | None = None
    outline_color: str | None = None
    outline_variant_color: str | None = None
    working_hours: dict | None = None
    supports_delivery: bool = False
    supports_pickup: bool = True
    payment_methods: list[str] = []
    yookassa_shop_id: str | None = None
    yookassa_secret_key: str | None = None
    loyalty_points_percent: float | None = None


class UpdateBusinessSettingsRequest(BaseModel):
    """Запрос на обновление настроек бизнеса."""

    name: str | None = None
    description: str | None = None
    currency: str | None = None
    timezone: str | None = None
    logo: str | None = None
    primary_color: str | None = None
    background_color: str | None = None
    text_color: str | None = None
    # Дополнительные цвета темы
    secondary_color: str | None = None
    tertiary_color: str | None = None
    error_color: str | None = None
    surface_color: str | None = None
    on_primary_color: str | None = None
    on_secondary_color: str | None = None
    on_tertiary_color: str | None = None
    on_error_color: str | None = None
    on_surface_color: str | None = None
    primary_container_color: str | None = None
    secondary_container_color: str | None = None
    tertiary_container_color: str | None = None
    error_container_color: str | None = None
    on_primary_container_color: str | None = None
    on_secondary_container_color: str | None = None
    on_tertiary_container_color: str | None = None
    on_error_container_color: str | None = None
    outline_color: str | None = None
    outline_variant_color: str | None = None
    working_hours: dict | None = None
    supports_delivery: bool | None = None
    supports_pickup: bool | None = None
    payment_methods: list[str] | None = None
    yookassa_shop_id: str | None = None
    yookassa_secret_key: str | None = None
    loyalty_points_percent: float | None = None


@router.get("/{business_slug}/settings", response_model=BusinessSettingsResponse)
async def get_business_settings(
    business_slug: str,
    db: AsyncSession = Depends(get_db),
):
    """
    Получить настройки бизнеса.
    
    ⚠️ ВНИМАНИЕ: В production здесь должна быть проверка авторизации!
    """
    import logging
    logger = logging.getLogger(__name__)
    
    try:
        from app.services.setting_service import SettingService
        from app.core.cache import cache_service, get_cache_key_business_settings

        # Пытаемся получить из кеша
        cache_key = get_cache_key_business_settings(business_slug)
        cached_result = await cache_service.get(cache_key)
        if cached_result is not None:
            logger.info(f"Returning cached settings for business: {business_slug}")
            return BusinessSettingsResponse(**cached_result)

        # Находим бизнес
        logger.info(f"Getting business settings for slug: {business_slug}")
        business_service = BusinessService(db)
        business = await business_service.get_by_slug(business_slug)

        if not business:
            logger.warning(f"Business with slug '{business_slug}' not found")
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Бизнес с slug '{business_slug}' не найден",
            )

        # Получаем настройки
        logger.info(f"Getting settings for business_id: {business.id}")
        setting_service = SettingService(db)
        settings = await setting_service.get_by_business_id(business.id)
        logger.info(f"Settings retrieved: {list(settings.keys())}")

        result = BusinessSettingsResponse(
            name=business.name,
            slug=business.slug,
            description=business.description,
            currency=business.currency,
            timezone=business.timezone,
            logo=settings.get("logo"),
            primary_color=settings.get("primary_color"),
            background_color=settings.get("background_color"),
            text_color=settings.get("text_color"),
            secondary_color=settings.get("secondary_color"),
            tertiary_color=settings.get("tertiary_color"),
            error_color=settings.get("error_color"),
            surface_color=settings.get("surface_color"),
            on_primary_color=settings.get("on_primary_color"),
            on_secondary_color=settings.get("on_secondary_color"),
            on_tertiary_color=settings.get("on_tertiary_color"),
            on_error_color=settings.get("on_error_color"),
            on_surface_color=settings.get("on_surface_color"),
            primary_container_color=settings.get("primary_container_color"),
            secondary_container_color=settings.get("secondary_container_color"),
            tertiary_container_color=settings.get("tertiary_container_color"),
            error_container_color=settings.get("error_container_color"),
            on_primary_container_color=settings.get("on_primary_container_color"),
            on_secondary_container_color=settings.get("on_secondary_container_color"),
            on_tertiary_container_color=settings.get("on_tertiary_container_color"),
            on_error_container_color=settings.get("on_error_container_color"),
            outline_color=settings.get("outline_color"),
            outline_variant_color=settings.get("outline_variant_color"),
            working_hours=settings.get("working_hours"),
            supports_delivery=settings.get("supports_delivery", False),
            supports_pickup=settings.get("supports_pickup", True),
            payment_methods=settings.get("payment_methods", []),
            yookassa_shop_id=settings.get("yookassa_shop_id"),
            yookassa_secret_key=settings.get("yookassa_secret_key"),
            loyalty_points_percent=float(business.loyalty_points_percent) if business.loyalty_points_percent else 1.0,
        )

        # Сохраняем в кеш (TTL 10 минут, так как настройки меняются редко)
        await cache_service.set(cache_key, result.model_dump(), ttl=600)

        return result
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting business settings: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Ошибка получения настроек: {str(e)}",
        )


@router.put("/{business_slug}/settings", response_model=BusinessSettingsResponse)
@router.patch("/{business_slug}/settings", response_model=BusinessSettingsResponse)
async def update_business_settings(
    business_slug: str,
    request: UpdateBusinessSettingsRequest,
    db: AsyncSession = Depends(get_db),
):
    """
    Обновить настройки бизнеса.
    
    ⚠️ ВНИМАНИЕ: В production здесь должна быть проверка авторизации!
    """
    from app.services.setting_service import SettingService
    from app.models.business import Business
    from sqlalchemy import update as sql_update

    # Находим бизнес
    business_service = BusinessService(db)
    business = await business_service.get_by_slug(business_slug)

    if not business:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Бизнес с slug '{business_slug}' не найден",
        )

    # Обновляем поля бизнеса
    update_data = {}
    if request.name is not None:
        update_data["name"] = request.name
    if request.description is not None:
        update_data["description"] = request.description
    if request.currency is not None:
        update_data["currency"] = request.currency
    if request.timezone is not None:
        update_data["timezone"] = request.timezone
    if request.loyalty_points_percent is not None:
        from decimal import Decimal
        # Валидация процента (от 0 до 100)
        if request.loyalty_points_percent < 0 or request.loyalty_points_percent > 100:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Процент начисления баллов должен быть от 0 до 100",
            )
        update_data["loyalty_points_percent"] = Decimal(str(request.loyalty_points_percent))

    if update_data:
        stmt = sql_update(Business).where(Business.id == business.id).values(**update_data)
        await db.execute(stmt)
        await db.commit()
        await db.refresh(business)

    # Обновляем настройки
    setting_service = SettingService(db)

    # Список ключей цветов, для которых None означает удаление
    color_keys = [
        "primary_color", "background_color", "text_color",
        "secondary_color", "tertiary_color", "error_color", "surface_color",
        "on_primary_color", "on_secondary_color", "on_tertiary_color",
        "on_error_color", "on_surface_color",
        "primary_container_color", "secondary_container_color",
        "tertiary_container_color", "error_container_color",
        "on_primary_container_color", "on_secondary_container_color",
        "on_tertiary_container_color", "on_error_container_color",
        "outline_color", "outline_variant_color",
    ]

    settings_to_update = {
        "logo": request.logo,
        "primary_color": request.primary_color,
        "background_color": request.background_color,
        "text_color": request.text_color,
        "secondary_color": request.secondary_color,
        "tertiary_color": request.tertiary_color,
        "error_color": request.error_color,
        "surface_color": request.surface_color,
        "on_primary_color": request.on_primary_color,
        "on_secondary_color": request.on_secondary_color,
        "on_tertiary_color": request.on_tertiary_color,
        "on_error_color": request.on_error_color,
        "on_surface_color": request.on_surface_color,
        "primary_container_color": request.primary_container_color,
        "secondary_container_color": request.secondary_container_color,
        "tertiary_container_color": request.tertiary_container_color,
        "error_container_color": request.error_container_color,
        "on_primary_container_color": request.on_primary_container_color,
        "on_secondary_container_color": request.on_secondary_container_color,
        "on_tertiary_container_color": request.on_tertiary_container_color,
        "on_error_container_color": request.on_error_container_color,
        "outline_color": request.outline_color,
        "outline_variant_color": request.outline_variant_color,
        "working_hours": request.working_hours,
        "supports_delivery": request.supports_delivery,
        "supports_pickup": request.supports_pickup,
        "payment_methods": request.payment_methods,
        "yookassa_shop_id": request.yookassa_shop_id,
        "yookassa_secret_key": request.yookassa_secret_key,
    }

    for key, value in settings_to_update.items():
        if key in color_keys and value is None:
            # Для цветов None означает удаление настройки (сброс к дефолтному)
            await setting_service.delete(business.id, key)
        elif value is not None:
            # Всегда сохраняем как {"value": ...} для единообразия
            await setting_service.set(business.id, key, {"value": value})

    # Обновляем бизнес в БД
    await db.refresh(business)

    # Получаем обновленные настройки
    settings = await setting_service.get_by_business_id(business.id)

    result = BusinessSettingsResponse(
        name=business.name,
        slug=business.slug,
        description=business.description,
        currency=business.currency,
        timezone=business.timezone,
        logo=settings.get("logo"),
        primary_color=settings.get("primary_color"),
        background_color=settings.get("background_color"),
        text_color=settings.get("text_color"),
        secondary_color=settings.get("secondary_color"),
        tertiary_color=settings.get("tertiary_color"),
        error_color=settings.get("error_color"),
        surface_color=settings.get("surface_color"),
        on_primary_color=settings.get("on_primary_color"),
        on_secondary_color=settings.get("on_secondary_color"),
        on_tertiary_color=settings.get("on_tertiary_color"),
        on_error_color=settings.get("on_error_color"),
        on_surface_color=settings.get("on_surface_color"),
        primary_container_color=settings.get("primary_container_color"),
        secondary_container_color=settings.get("secondary_container_color"),
        tertiary_container_color=settings.get("tertiary_container_color"),
        error_container_color=settings.get("error_container_color"),
        on_primary_container_color=settings.get("on_primary_container_color"),
        on_secondary_container_color=settings.get("on_secondary_container_color"),
        on_tertiary_container_color=settings.get("on_tertiary_container_color"),
        on_error_container_color=settings.get("on_error_container_color"),
        outline_color=settings.get("outline_color"),
        outline_variant_color=settings.get("outline_variant_color"),
        working_hours=settings.get("working_hours"),
        supports_delivery=settings.get("supports_delivery", False),
        supports_pickup=settings.get("supports_pickup", True),
        payment_methods=settings.get("payment_methods", []),
        yookassa_shop_id=settings.get("yookassa_shop_id"),
        yookassa_secret_key=settings.get("yookassa_secret_key"),
        loyalty_points_percent=float(business.loyalty_points_percent) if business.loyalty_points_percent else 1.0,
    )

    # Инвалидируем кеш настроек
    from app.core.cache import cache_service, get_cache_key_business_settings
    await cache_service.delete(get_cache_key_business_settings(business_slug))

    return result
