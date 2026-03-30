"""Сервис для работы с продуктами."""
from datetime import datetime
from decimal import Decimal
from sqlalchemy import select, insert, delete
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload
from uuid import UUID

from app.models.product import Product
from app.models.business import Business
from app.models.category import Category
from app.models.product_category import product_categories


class ProductService:
    """Сервис для работы с продуктами."""

    def __init__(self, db: AsyncSession):
        self.db = db

    async def get_by_business_slug(
        self,
        business_slug: str,
        category_id: UUID | None = None,
        search_query: str | None = None,
        min_price: Decimal | None = None,
        max_price: Decimal | None = None,
        page: int = 1,
        limit: int = 20,
        include_inactive: bool = False,
    ) -> list[Product]:
        """Получить продукты бизнеса с фильтрацией."""
        # Сначала находим бизнес
        stmt_business = select(Business).where(Business.slug == business_slug)
        result = await self.db.execute(stmt_business)
        business = result.scalar_one_or_none()

        if not business:
            return []

        # Строим запрос для продуктов
        stmt = select(Product).options(
            selectinload(Product.categories)
        ).where(
            Product.business_id == business.id,
        )
        
        # Фильтр по is_active только если не запрашиваются неактивные товары
        if not include_inactive:
            stmt = stmt.where(Product.is_active == True)  # noqa: E712

        # Фильтр по категории
        if category_id:
            stmt = stmt.join(Product.categories).where(Category.id == category_id)

        # Поиск по названию и SKU
        if search_query:
            stmt = stmt.where(
                (Product.title.ilike(f"%{search_query}%")) |
                (Product.sku.ilike(f"%{search_query}%"))
            )

        # Фильтр по минимальной цене
        if min_price is not None:
            stmt = stmt.where(Product.price >= min_price)

        # Фильтр по максимальной цене
        if max_price is not None:
            stmt = stmt.where(Product.price <= max_price)

        # Пагинация
        offset = (page - 1) * limit
        stmt = stmt.offset(offset).limit(limit)

        result = await self.db.execute(stmt)
        return list(result.scalars().all())

    async def get_by_id(self, product_id: UUID) -> Product | None:
        """Получить продукт по ID."""
        stmt = select(Product).where(Product.id == product_id)
        result = await self.db.execute(stmt)
        return result.scalar_one_or_none()

    async def create(
        self,
        business_id: UUID,
        title: str,
        price: Decimal,
        currency: str = "RUB",
        description: str | None = None,
        sku: str | None = None,
        image_url: str | None = None,
        variations: dict | None = None,
        is_active: bool = True,
        category_ids: list[UUID] | None = None,
        discount_percentage: Decimal | None = None,
        discount_price: Decimal | None = None,
        discount_valid_from: datetime | None = None,
        discount_valid_until: datetime | None = None,
        stock_quantity: int | None = None,
    ) -> UUID:  # Возвращаем только ID, чтобы избежать проблем с lazy loading
        """Создать новый продукт."""
        product = Product(
            business_id=business_id,
            title=title,
            description=description,
            price=price,
            currency=currency,
            sku=sku,
            image_url=image_url,
            variations=variations,
            is_active=is_active,
            discount_percentage=discount_percentage,
            discount_price=discount_price,
            discount_valid_from=discount_valid_from,
            discount_valid_until=discount_valid_until,
            stock_quantity=stock_quantity,
        )
        self.db.add(product)
        await self.db.flush()  # Получаем ID продукта
        
        # Сохраняем ID ДО commit, чтобы избежать проблем с lazy loading
        product_id = product.id

        # Добавляем связи с категориями через прямую вставку в M2M таблицу
        if category_ids:
            from app.models.product_category import product_categories
            from sqlalchemy import insert
            
            # Вставляем связи напрямую в M2M таблицу
            # Это избегает проблем с lazy loading через relationship
            for category_id in category_ids:
                stmt = insert(product_categories).values(
                    product_id=product_id,
                    category_id=category_id,
                )
                await self.db.execute(stmt)
            await self.db.flush()  # Сохраняем связи

        await self.db.commit()
        
        # Возвращаем только ID, чтобы избежать проблем с lazy loading после commit
        return product_id

    async def update(
        self,
        product_id: UUID,
        title: str | None = None,
        description: str | None = None,
        price: Decimal | None = None,
        currency: str | None = None,
        sku: str | None = None,
        image_url: str | None = None,
        variations: dict | None = None,
        is_active: bool | None = None,
        category_ids: list[UUID] | None = None,
        discount_percentage: Decimal | None = None,
        discount_price: Decimal | None = None,
        discount_valid_from: datetime | None = None,
        discount_valid_until: datetime | None = None,
        stock_quantity: int | None = None,
    ) -> Product | None:
        """Обновить продукт."""
        product = await self.get_by_id(product_id)
        if not product:
            return None

        if title is not None:
            product.title = title
        if description is not None:
            product.description = description
        if price is not None:
            product.price = price
        if currency is not None:
            product.currency = currency
        if sku is not None:
            product.sku = sku
        if image_url is not None:
            product.image_url = image_url
        if variations is not None:
            product.variations = variations
        if is_active is not None:
            product.is_active = is_active
        # Поля для скидок
        if discount_percentage is not None:
            product.discount_percentage = discount_percentage
        # Управление складом
        if stock_quantity is not None:
            product.stock_quantity = stock_quantity
        if discount_price is not None:
            product.discount_price = discount_price
        if discount_valid_from is not None:
            product.discount_valid_from = discount_valid_from
        if discount_valid_until is not None:
            product.discount_valid_until = discount_valid_until

        # Обновляем категории если указаны
        if category_ids is not None:
            # Удаляем старые связи
            stmt_delete = delete(product_categories).where(
                product_categories.c.product_id == product_id
            )
            await self.db.execute(stmt_delete)
            await self.db.flush()

            # Добавляем новые связи
            for category_id in category_ids:
                stmt_insert = insert(product_categories).values(
                    product_id=product_id,
                    category_id=category_id,
                )
                await self.db.execute(stmt_insert)
            await self.db.flush()

        await self.db.commit()
        await self.db.refresh(product)
        return product

    async def delete(self, product_id: UUID) -> bool:
        """Удалить продукт."""
        product = await self.get_by_id(product_id)
        if not product:
            return False

        try:
            # Удаляем связи с категориями
            stmt_delete = delete(product_categories).where(
                product_categories.c.product_id == product_id
            )
            await self.db.execute(stmt_delete)
            await self.db.flush()

            # Удаляем сам продукт
            stmt_delete_product = delete(Product).where(Product.id == product_id)
            await self.db.execute(stmt_delete_product)
            await self.db.commit()
            return True
        except Exception:
            # Откатываем транзакцию при ошибке
            await self.db.rollback()
            raise

    def get_discounted_price(self, product: Product) -> Decimal:
        """
        Получить цену товара с учётом скидки.
        
        Проверяет активность скидки и возвращает цену со скидкой или обычную цену.
        
        Args:
            product: Продукт
        
        Returns:
            Цена с учётом скидки
        """
        now = datetime.utcnow()
        
        # Проверяем, активна ли скидка
        is_discount_active = False
        
        if product.discount_percentage is not None or product.discount_price is not None:
            # Проверяем даты действия скидки
            if product.discount_valid_from and now < product.discount_valid_from:
                is_discount_active = False
            elif product.discount_valid_until and now > product.discount_valid_until:
                is_discount_active = False
            else:
                is_discount_active = True
        
        if not is_discount_active:
            return product.price
        
        # Если указана фиксированная цена со скидкой
        if product.discount_price is not None:
            return product.discount_price
        
        # Если указан процент скидки
        if product.discount_percentage is not None:
            discount_amount = product.price * (product.discount_percentage / Decimal("100"))
            return (product.price - discount_amount).quantize(Decimal("0.01"))
        
        return product.price

