#!/usr/bin/env python3
"""
Скрипт для создания бизнеса в production базе данных.

Использование:
    export DATABASE_URL="postgresql://user:password@host:5432/dbname"
    python create_production_business.py
"""
import asyncio
import os
import sys
import uuid

from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker
from sqlalchemy import select

# Добавляем путь к app
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from app.models.business import Business
from app.models.user import User
from app.services.business_service import BusinessService


async def create_production_business():
    """Создать бизнес в production базе данных."""
    production_db_url = os.getenv('DATABASE_URL')
    
    if not production_db_url:
        print("❌ Ошибка: DATABASE_URL не установлен")
        print()
        print("Установите переменную окружения DATABASE_URL:")
        print("  export DATABASE_URL='postgresql://user:password@host:5432/dbname'")
        sys.exit(1)
    
    # Конвертируем postgresql:// в postgresql+asyncpg:// если нужно
    if not production_db_url.startswith('postgresql+asyncpg://'):
        if production_db_url.startswith('postgresql://'):
            production_db_url = production_db_url.replace('postgresql://', 'postgresql+asyncpg://', 1)
        else:
            print("❌ Ошибка: DATABASE_URL должен начинаться с 'postgresql://' или 'postgresql+asyncpg://'")
            sys.exit(1)
    
    print("=" * 50)
    print("🏢 СОЗДАНИЕ БИЗНЕСА В PRODUCTION")
    print("=" * 50)
    print()
    
    # Подключаемся к production БД
    print(f"🔌 Подключение к production БД...")
    engine = create_async_engine(production_db_url, echo=False)
    async_session = async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)
    
    async with async_session() as session:
        business_service = BusinessService(session)
        
        # Проверяем, существует ли бизнес
        business_slug = "default-business"
        existing_business = await business_service.get_by_slug(business_slug)
        
        if existing_business:
            print(f"✅ Бизнес '{business_slug}' уже существует:")
            print(f"   ID: {existing_business.id}")
            print(f"   Название: {existing_business.name}")
            print(f"   Slug: {existing_business.slug}")
            return existing_business
        
        # Ищем пользователя для owner_id
        stmt = select(User).limit(1)
        result = await session.execute(stmt)
        user = result.scalar_one_or_none()
        
        if not user:
            # Создаем дефолтного пользователя
            print("👤 Создание дефолтного пользователя...")
            user = User(
                id=uuid.uuid4(),
                telegram_id=123456789,  # Тестовый ID
                role="owner",
            )
            session.add(user)
            await session.commit()
            await session.refresh(user)
            print(f"✅ Создан пользователь (ID: {user.id}, role: {user.role})")
        
        # Создаем бизнес
        print(f"🏢 Создание бизнеса '{business_slug}'...")
        business = await business_service.create(
            owner_id=user.id,
            name="Мой магазин",
            slug=business_slug,
            description="Основной бизнес",
        )
        
        print()
        print("=" * 50)
        print("✅ БИЗНЕС УСПЕШНО СОЗДАН!")
        print("=" * 50)
        print(f"   ID: {business.id}")
        print(f"   Название: {business.name}")
        print(f"   Slug: {business.slug}")
        print(f"   Владелец: {user.role} (ID: {user.id})")
        print("=" * 50)
        
        return business
    
    await engine.dispose()


if __name__ == '__main__':
    asyncio.run(create_production_business())

