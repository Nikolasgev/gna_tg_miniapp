"""Сервис для работы с заказами."""
from datetime import datetime, timedelta
from decimal import Decimal
from sqlalchemy import select, delete
from sqlalchemy.ext.asyncio import AsyncSession
from uuid import UUID

from app.models.order import Order, OrderItem
from app.models.product import Product
from app.models.business import Business
from app.models.category import Category
from sqlalchemy.orm import selectinload


class OrderService:
    """Сервис для работы с заказами."""

    def __init__(self, db: AsyncSession):
        self.db = db

    async def create_order(
        self,
        business_slug: str,
        customer_name: str,
        customer_phone: str,
        customer_address: str | None,
        items: list[dict],
        payment_method: str,
        delivery_method: str = "pickup",
        user_telegram_id: int | None = None,
        promocode: str | None = None,
        loyalty_points_to_spend: Decimal | None = None,
    ) -> Order:
        """
        Создать заказ.

        Валидирует товары, перечитывает цены из БД и вычисляет итоговую сумму.
        """
        # Находим бизнес
        stmt_business = select(Business).where(Business.slug == business_slug)
        result = await self.db.execute(stmt_business)
        business = result.scalar_one_or_none()

        if not business:
            raise ValueError(f"Бизнес с slug '{business_slug}' не найден")

        # Валидируем товары и перечитываем цены
        total_amount = Decimal("0")
        order_items_data = []

        for item in items:
            product_id = UUID(item["product_id"])
            quantity = int(item["quantity"])
            selected_variations = item.get("selected_variations") or {}

            # Получаем продукт из БД с категориями
            stmt_product = (
                select(Product)
                .options(selectinload(Product.categories))
                .where(
                    Product.id == product_id,
                    Product.business_id == business.id,
                    Product.is_active == True,  # noqa: E712
                )
            )
            result = await self.db.execute(stmt_product)
            product = result.scalar_one_or_none()

            if not product:
                raise ValueError(f"Продукт с ID '{product_id}' не найден или неактивен")

            # Проверяем наличие товара на складе
            if product.stock_quantity is not None and product.stock_quantity < quantity:
                raise ValueError(
                    f"Недостаточно товара '{product.title}' на складе. "
                    f"Доступно: {product.stock_quantity}, запрошено: {quantity}"
                )

            # Используем цену из БД с учётом скидок (не доверяем клиенту)
            from app.services.product_service import ProductService
            product_service = ProductService(self.db)
            unit_price = product_service.get_discounted_price(product)
            
            # Добавляем цены выбранных вариаций
            if product.variations and selected_variations:
                variations = product.variations
                for var_key, var_value in selected_variations.items():
                    if var_key in variations:
                        var_data = variations[var_key]
                        # Если вариация - объект с ценами {значение: цена}
                        if isinstance(var_data, dict) and var_value in var_data:
                            variation_price = var_data[var_value]
                            if isinstance(variation_price, (int, float)):
                                unit_price += Decimal(str(variation_price))
            
            item_total = unit_price * quantity
            total_amount += item_total

            # Добавляем доплату за каждую категорию товара (для каждого товара)
            # Если товар в нескольких категориях, доплата добавляется за каждую категорию
            for category in product.categories:
                if category.surcharge > 0:
                    # Доплата умножается на количество товара
                    total_amount += category.surcharge * quantity

            # Сохраняем вариации и заметку в metadata
            item_metadata = {}
            if selected_variations:
                item_metadata["selected_variations"] = selected_variations
            if item.get("note"):
                item_metadata["note"] = item["note"]
            # Сохраняем категории товара
            if product.categories:
                item_metadata["category_names"] = [cat.name for cat in product.categories]
                item_metadata["category_surcharges"] = {cat.name: float(cat.surcharge) for cat in product.categories if cat.surcharge > 0}
            
            order_items_data.append({
                "product": product,
                "title_snapshot": product.title,
                "quantity": quantity,
                "unit_price": unit_price,
                "total_price": item_total,
                "item_metadata": item_metadata if item_metadata else None,
            })

        # Рассчитываем стоимость доставки, если выбрана доставка
        delivery_cost = Decimal("0")
        if delivery_method == "delivery" and customer_address:
            try:
                from app.services.delivery_service import DeliveryService
                from app.config import settings
                import logging
                
                logger = logging.getLogger(__name__)
                
                # Адрес отправления из настроек
                from_address = {
                    "fullname": settings.pickup_address_fullname,
                    "coordinates": settings.pickup_address_coordinates,
                    "city": settings.pickup_address_city,
                    "country": settings.pickup_address_country,
                    "street": settings.pickup_address_street,
                }
                
                # Адрес назначения - адрес клиента
                # Пытаемся получить координаты через геокодер
                to_coordinates = [37.6173, 55.7558]  # Координаты по умолчанию (центр Москвы)
                
                try:
                    from app.services.geocoder_service import GeocoderService
                    from app.config import settings
                    
                    geocoder = GeocoderService(api_key=settings.yandex_geocoder_api_key)
                    geocoded = await geocoder.geocode(customer_address)
                    if geocoded:
                        to_coordinates = list(geocoded)
                except Exception as geocode_error:
                    logger.warning(f"Failed to geocode customer address '{customer_address}': {geocode_error}, using default coordinates")
                
                to_address = {
                    "fullname": customer_address,
                    "coordinates": to_coordinates,
                    "city": "Москва",
                    "country": "Россия",
                    "street": customer_address,
                }
                
                # Подготавливаем товары для расчета доставки
                delivery_items = []
                for item_data in order_items_data:
                    product = item_data["product"]
                    quantity = item_data["quantity"]
                    
                    # Оцениваем вес товара (можно добавить поле weight в модель Product)
                    # Используем минимальный вес для снижения стоимости: 0.1 кг на единицу товара
                    # Яндекс Доставка имеет минимальные требования, поэтому используем минимальные значения
                    estimated_weight = Decimal("0.1") * quantity
                    
                    delivery_items.append({
                        "quantity": quantity,
                        "weight": float(estimated_weight),
                        "size": {
                            "length": 0.05,  # Минимальные размеры в метрах для снижения стоимости
                            "width": 0.05,
                            "height": 0.05,
                        },
                    })
                
                # Рассчитываем стоимость доставки
                # Пробуем несколько классов такси, чтобы выбрать самый дешевый
                delivery_service = DeliveryService()
                all_offers = []
                
                # Пробуем разные классы такси
                for taxi_class in ["courier", "express"]:
                    try:
                        delivery_result = await delivery_service.calculate_delivery_cost(
                            from_address=from_address,
                            to_address=to_address,
                            items=delivery_items,
                            taxi_classes=[taxi_class],
                        )
                        
                        if delivery_result.get("offers"):
                            for offer in delivery_result["offers"]:
                                if offer.get("taxi_class") == taxi_class:
                                    all_offers.append(offer)
                    except Exception as e:
                        logger.warning(f"Failed to calculate delivery cost for {taxi_class}: {e}")
                        continue
                
                # Выбираем самый дешевый вариант
                if all_offers:
                    # Сортируем по цене (с учетом surge_ratio)
                    all_offers.sort(key=lambda o: float(
                        o.get("price", {}).get("total_price_with_vat", 
                        o.get("price", {}).get("total_price", "999999"))
                    ))
                    
                    cheapest_offer = all_offers[0]
                    price_info = cheapest_offer.get("price", {})
                    delivery_cost_str = price_info.get("total_price_with_vat") or price_info.get("total_price", "0")
                    delivery_cost = Decimal(str(delivery_cost_str))
                    
                    surge_ratio = price_info.get("surge_ratio", 1.0)
                    if surge_ratio > 1.5:
                        logger.warning(f"High surge pricing detected: {surge_ratio}x. Delivery cost: {delivery_cost} {business.currency}")
                    
                    logger.info(f"Delivery cost calculated: {delivery_cost} {business.currency} (class: {cheapest_offer.get('taxi_class')}, surge: {surge_ratio}x)")
                else:
                    logger.warning("No delivery offers found, delivery cost set to 0")
                    
            except Exception as e:
                import logging
                logger = logging.getLogger(__name__)
                logger.error(f"Error calculating delivery cost: {e}", exc_info=True)
                # Если не удалось рассчитать доставку, продолжаем без нее
                # В production можно либо выбросить ошибку, либо использовать фиксированную стоимость
                delivery_cost = Decimal("0")

        # Добавляем стоимость доставки к итоговой сумме
        subtotal_amount = total_amount + delivery_cost  # Сумма до применения скидок
        logger.info(f"Order calculation: items_total={total_amount}, delivery_cost={delivery_cost}, subtotal={subtotal_amount}")
        
        # Применяем промокод, если указан
        promocode_obj = None
        promocode_discount = Decimal("0")
        if promocode:
            from app.services.promocode_service import PromocodeService
            promocode_service = PromocodeService(self.db)
            
            promocode_obj, error = await promocode_service.validate_promocode(
                code=promocode,
                business_id=business.id,
                order_amount=subtotal_amount,
                user_telegram_id=user_telegram_id,
            )
            
            if error:
                raise ValueError(f"Ошибка применения промокода: {error}")
            
            promocode_discount = await promocode_service.calculate_discount(
                promocode=promocode_obj,
                order_amount=subtotal_amount,
            )
        
        # Применяем баллы лояльности, если указаны
        loyalty_discount = Decimal("0")
        loyalty_points_spent = Decimal("0")
        if loyalty_points_to_spend and user_telegram_id:
            from app.services.loyalty_service import LoyaltyService
            loyalty_service = LoyaltyService(self.db)
            
            account = await loyalty_service.get_or_create_account(
                business_id=business.id,
                user_telegram_id=user_telegram_id,
            )
            
            # Рассчитываем скидку от баллов (1 балл = 1 рубль по умолчанию)
            loyalty_discount = await loyalty_service.calculate_discount_from_points(
                points=loyalty_points_to_spend,
                points_per_rub=Decimal("1"),
            )
            
            # Скидка от баллов не может быть больше 90% суммы заказа после промокода
            amount_after_promocode = subtotal_amount - promocode_discount
            max_loyalty_discount = amount_after_promocode * Decimal("0.90")  # Максимум 90%
            loyalty_discount = min(loyalty_discount, max_loyalty_discount, amount_after_promocode)
            
            if loyalty_discount > 0:
                # Пересчитываем фактически потраченные баллы
                loyalty_points_spent = loyalty_points_to_spend
        
        # Рассчитываем итоговую сумму
        total_discount = promocode_discount + loyalty_discount
        total_amount = max(Decimal("0"), subtotal_amount - total_discount)  # Не может быть отрицательным
        logger.info(f"Order final calculation: subtotal={subtotal_amount}, discount={total_discount}, final_total={total_amount} (includes delivery: {delivery_cost})")

        # Рассчитываем баллы, которые будут начислены за заказ (процент от суммы, по умолчанию 1%)
        loyalty_points_earned = Decimal("0")
        if user_telegram_id and total_amount > 0:
            from app.services.loyalty_service import LoyaltyService
            loyalty_service = LoyaltyService(self.db)
            # Получаем процент начисления баллов из настроек бизнеса (по умолчанию 1%)
            loyalty_percent = business.loyalty_points_percent if business.loyalty_points_percent else Decimal("1.00")
            loyalty_points_earned = await loyalty_service.calculate_points_earned(
                order_amount=total_amount,
                percent=loyalty_percent,
            )

        # Сохраняем delivery_cost и delivery_method в order_metadata
        order_metadata = {
            "delivery_method": delivery_method,
            "delivery_cost": float(delivery_cost),
        }

        # Создаем заказ
        order = Order(
            business_id=business.id,
            user_telegram_id=user_telegram_id,
            customer_name=customer_name,
            customer_phone=customer_phone,
            customer_address=customer_address,
            subtotal_amount=subtotal_amount,
            discount_amount=total_discount,
            total_amount=total_amount,
            currency=business.currency,
            status="new",
            payment_status="pending",
            payment_method=payment_method,
            promocode_id=promocode_obj.id if promocode_obj else None,
            loyalty_points_earned=loyalty_points_earned,
            loyalty_points_spent=loyalty_points_spent if loyalty_points_spent > 0 else None,
            order_metadata=order_metadata,
        )

        self.db.add(order)
        await self.db.flush()  # Получаем ID заказа

        # Создаем элементы заказа
        for item_data in order_items_data:
            order_item = OrderItem(
                order_id=order.id,
                product_id=item_data["product"].id,
                title_snapshot=item_data["title_snapshot"],
                quantity=item_data["quantity"],
                unit_price=item_data["unit_price"],
                total_price=item_data["total_price"],
                item_metadata=item_data.get("item_metadata"),
            )
            self.db.add(order_item)

        await self.db.flush()  # Сохраняем элементы заказа

        # Применяем промокод (создаём запись об использовании)
        if promocode_obj:
            from app.services.promocode_service import PromocodeService
            promocode_service = PromocodeService(self.db)
            await promocode_service.apply_promocode(
                promocode=promocode_obj,
                order=order,
                discount_amount=promocode_discount,
                order_amount_before=subtotal_amount,
                order_amount_after=total_amount,
            )

        # Списываем баллы лояльности, если указаны
        if loyalty_points_spent > 0 and user_telegram_id:
            from app.services.loyalty_service import LoyaltyService
            loyalty_service = LoyaltyService(self.db)
            
            account = await loyalty_service.get_or_create_account(
                business_id=business.id,
                user_telegram_id=user_telegram_id,
            )
            
            await loyalty_service.spend_points(
                account=account,
                points=loyalty_points_spent,
                order=order,
                description=f"Списано баллов за заказ #{order.id}",
            )

        await self.db.commit()
        await self.db.refresh(order)

        return order

    async def get_by_business_slug(
        self,
        business_slug: str,
        page: int = 1,
        limit: int = 20,
    ) -> list[Order]:
        """Получить заказы бизнеса."""
        from sqlalchemy.orm import selectinload

        # Находим бизнес
        stmt_business = select(Business).where(Business.slug == business_slug)
        result = await self.db.execute(stmt_business)
        business = result.scalar_one_or_none()

        if not business:
            return []

        # Получаем заказы с элементами
        offset = (page - 1) * limit
        stmt = (
            select(Order)
            .options(selectinload(Order.items))
            .where(Order.business_id == business.id)
            .order_by(Order.created_at.desc())
            .offset(offset)
            .limit(limit)
        )

        result = await self.db.execute(stmt)
        return list(result.scalars().all())

    async def get_by_user_telegram_id(
        self,
        user_telegram_id: int,
        business_slug: str | None = None,
        page: int = 1,
        limit: int = 20,
    ) -> list[Order]:
        """Получить заказы пользователя по Telegram ID."""
        from sqlalchemy.orm import selectinload

        stmt = (
            select(Order)
            .options(selectinload(Order.items))
            .where(Order.user_telegram_id == user_telegram_id)
        )

        # Если указан business_slug, фильтруем по нему
        if business_slug:
            stmt_business = select(Business).where(Business.slug == business_slug)
            result_business = await self.db.execute(stmt_business)
            business = result_business.scalar_one_or_none()
            if business:
                stmt = stmt.where(Order.business_id == business.id)

        stmt = stmt.order_by(Order.created_at.desc())

        # Пагинация
        offset = (page - 1) * limit
        stmt = stmt.offset(offset).limit(limit)

        result = await self.db.execute(stmt)
        return list(result.scalars().all())

    async def get_by_id(self, order_id: UUID) -> Order | None:
        """Получить заказ по ID."""
        from sqlalchemy.orm import selectinload

        stmt = (
            select(Order)
            .options(selectinload(Order.items))
            .where(Order.id == order_id)
        )
        result = await self.db.execute(stmt)
        return result.scalar_one_or_none()

    async def cancel_order(self, order_id: UUID) -> Order | None:
        """
        Отменить заказ.
        
        Заказ можно отменить только если его статус 'new' или 'accepted'.
        
        Returns:
            Обновленный заказ или None, если заказ не найден или не может быть отменен
        """
        order = await self.get_by_id(order_id)
        if not order:
            return None

        # Проверяем, можно ли отменить заказ
        if order.status not in ["new", "accepted"]:
            raise ValueError(
                f"Заказ можно отменить только со статусом 'new' или 'accepted'. "
                f"Текущий статус: {order.status}"
            )

        # Обновляем статус на 'cancelled'
        old_status = order.status
        order.status = "cancelled"
        
        # Возвращаем товар на склад при отмене заказа
        if old_status in ["new", "accepted"]:
            await self._restore_stock(order)
        
        # Если оплата была онлайн и еще не обработана, можно также обновить статус оплаты
        # Но для простоты оставляем payment_status как есть
        
        await self.db.commit()
        await self.db.refresh(order)
        return order

    async def update_status(
        self,
        order_id: UUID,
        status: str | None = None,
        payment_status: str | None = None,
    ) -> Order | None:
        """
        Обновить статус заказа и/или статус оплаты.
        
        Args:
            order_id: ID заказа
            status: Новый статус заказа (new, accepted, preparing, ready, cancelled, completed)
            payment_status: Новый статус оплаты (pending, paid, failed, refunded)
        
        Returns:
            Обновленный заказ или None, если заказ не найден
        """
        order = await self.get_by_id(order_id)
        if not order:
            return None

        if status is not None:
            # Валидация статуса
            valid_statuses = ["new", "accepted", "preparing", "ready", "cancelled", "completed"]
            if status not in valid_statuses:
                raise ValueError(f"Недопустимый статус: {status}. Допустимые: {', '.join(valid_statuses)}")
            
            old_status = order.status
            order.status = status
            
            # Автоматическое списание товара со склада при подтверждении заказа
            if old_status != "accepted" and status == "accepted":
                await self._deduct_stock(order)
            
            # Возврат товара на склад при отмене заказа
            if old_status in ["new", "accepted"] and status == "cancelled":
                await self._restore_stock(order)

        if payment_status is not None:
            # Валидация статуса оплаты
            valid_payment_statuses = ["pending", "paid", "failed", "refunded"]
            if payment_status not in valid_payment_statuses:
                raise ValueError(
                    f"Недопустимый статус оплаты: {payment_status}. "
                    f"Допустимые: {', '.join(valid_payment_statuses)}"
                )
            
            # Проверяем, меняется ли статус на "paid"
            was_paid = order.payment_status == "paid"
            order.payment_status = payment_status
            
            # Если статус меняется на "paid" и ранее он не был "paid", начисляем баллы
            if payment_status == "paid" and not was_paid:
                try:
                    await self.award_loyalty_points(order_id)
                except Exception as e:
                    # Логируем ошибку, но не прерываем обновление статуса
                    import logging
                    logger = logging.getLogger(__name__)
                    logger.error(f"Ошибка при начислении баллов лояльности для заказа {order_id}: {e}", exc_info=True)

        await self.db.commit()
        await self.db.refresh(order)
        return order

    async def delete_old_orders(self, days: int = 7) -> int:
        """
        Удалить заказы со статусами 'cancelled' или 'completed',
        которые были обновлены более указанного количества дней назад.
        
        Args:
            days: Количество дней (по умолчанию 7)
        
        Returns:
            Количество удаленных заказов
        """
        # Вычисляем дату, до которой нужно удалить заказы
        cutoff_date = datetime.utcnow() - timedelta(days=days)
        
        # Находим заказы для удаления
        stmt = select(Order).where(
            Order.status.in_(["cancelled", "completed"]),
            Order.updated_at < cutoff_date
        )
        result = await self.db.execute(stmt)
        orders_to_delete = result.scalars().all()
        
        if not orders_to_delete:
            return 0
        
        # Получаем ID заказов для удаления
        order_ids = [order.id for order in orders_to_delete]
        
        # Удаляем элементы заказов (order_items) сначала из-за внешнего ключа
        delete_items_stmt = delete(OrderItem).where(OrderItem.order_id.in_(order_ids))
        await self.db.execute(delete_items_stmt)
        
        # Удаляем сами заказы
        delete_orders_stmt = delete(Order).where(Order.id.in_(order_ids))
        result = await self.db.execute(delete_orders_stmt)
        
        await self.db.commit()
        
        return len(orders_to_delete)

    async def award_loyalty_points(self, order_id: UUID) -> bool:
        """
        Начислить баллы лояльности за заказ.
        
        Вызывается после оплаты или завершения заказа.
        Баллы начисляются только один раз.
        
        Args:
            order_id: ID заказа
        
        Returns:
            True если баллы были начислены, False если заказ не найден или баллы уже начислены
        """
        order = await self.get_by_id(order_id)
        if not order or not order.user_telegram_id:
            return False

        # Всегда проверяем, есть ли уже транзакция начисления (защита от двойного начисления)
        from app.models.loyalty import LoyaltyTransaction
        from sqlalchemy import select, and_
        
        stmt = select(LoyaltyTransaction).where(
            and_(
                LoyaltyTransaction.order_id == order_id,
                LoyaltyTransaction.transaction_type == "earned",
            )
        )
        result = await self.db.execute(stmt)
        existing_transaction = result.scalar_one_or_none()
        
        if existing_transaction:
            return False  # Баллы уже начислены

        # Проверяем, есть ли баллы для начисления
        points_to_award = order.loyalty_points_earned or Decimal("0")
        if points_to_award <= 0:
            return False  # Нет баллов для начисления

        # Начисляем баллы
        from app.services.loyalty_service import LoyaltyService
        loyalty_service = LoyaltyService(self.db)
        
        account = await loyalty_service.get_or_create_account(
            business_id=order.business_id,
            user_telegram_id=order.user_telegram_id,
        )
        
        await loyalty_service.earn_points(
            account=account,
            points=points_to_award,
            order=order,
            description=f"Начислено за заказ #{order.id}",
        )
        
        await self.db.commit()
        return True

    async def _deduct_stock(self, order: Order) -> None:
        """
        Списать товар со склада при подтверждении заказа.
        
        Вызывается автоматически при изменении статуса заказа на 'accepted'.
        """
        import logging
        logger = logging.getLogger(__name__)
        
        # Загружаем элементы заказа с продуктами
        from sqlalchemy.orm import selectinload
        stmt = (
            select(Order)
            .options(selectinload(Order.items).selectinload(OrderItem.product))
            .where(Order.id == order.id)
        )
        result = await self.db.execute(stmt)
        order_with_items = result.scalar_one()
        
        for item in order_with_items.items:
            product = item.product
            if product.stock_quantity is not None:
                # Проверяем, что товара достаточно (на случай параллельных заказов)
                if product.stock_quantity < item.quantity:
                    logger.warning(
                        f"Недостаточно товара '{product.title}' на складе для заказа {order.id}. "
                        f"Доступно: {product.stock_quantity}, требуется: {item.quantity}"
                    )
                    raise ValueError(
                        f"Недостаточно товара '{product.title}' на складе. "
                        f"Доступно: {product.stock_quantity}, требуется: {item.quantity}"
                    )
                
                # Списываем товар со склада
                product.stock_quantity -= item.quantity
                logger.info(
                    f"Списано {item.quantity} единиц товара '{product.title}' со склада. "
                    f"Остаток: {product.stock_quantity}"
                )
        
        await self.db.flush()

    async def _restore_stock(self, order: Order) -> None:
        """
        Вернуть товар на склад при отмене заказа.
        
        Вызывается автоматически при отмене заказа со статусом 'new' или 'accepted'.
        """
        import logging
        logger = logging.getLogger(__name__)
        
        # Загружаем элементы заказа с продуктами
        from sqlalchemy.orm import selectinload
        stmt = (
            select(Order)
            .options(selectinload(Order.items).selectinload(OrderItem.product))
            .where(Order.id == order.id)
        )
        result = await self.db.execute(stmt)
        order_with_items = result.scalar_one()
        
        for item in order_with_items.items:
            product = item.product
            if product.stock_quantity is not None:
                # Возвращаем товар на склад
                product.stock_quantity += item.quantity
                logger.info(
                    f"Возвращено {item.quantity} единиц товара '{product.title}' на склад. "
                    f"Остаток: {product.stock_quantity}"
                )
        
        await self.db.flush()

