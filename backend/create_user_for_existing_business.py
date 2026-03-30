#!/usr/bin/env python3
"""
Скрипт для создания пользователя и назначения его владельцем существующего бизнеса.

Использование:
    export DATABASE_URL="postgresql://user:password@host:5432/dbname"
    python create_user_for_existing_business.py --username newuser --password password123 --business-slug default-business
"""
import asyncio
import os
import sys
import argparse

from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker
from sqlalchemy import select

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from app.models.user import User
from app.models.business import Business
from app.services.user_service import UserService
from app.services.business_service import BusinessService


async def create_user_for_business(
    username: str,
    password: str,
    business_slug: str,
    email: str | None = None,
):
    """Создать пользователя и назначить его владельцем существующего бизнеса."""
    production_db_url = os.getenv('DATABASE_URL')
    
    if not production_db_url:
        print("❌ Ошибка: DATABASE_URL не установлен")
        sys.exit(1)
    
    # Конвертируем postgresql:// в postgresql+asyncpg:// если нужно
    if not production_db_url.startswith('postgresql+asyncpg://'):
        if production_db_url.startswith('postgresql://'):
            production_db_url = production_db_url.replace('postgresql://', 'postgresql+asyncpg://', 1)
    
    print("=" * 50)
    print("👤 СОЗДАНИЕ ПОЛЬЗОВАТЕЛЯ ДЛЯ СУЩЕСТВУЮЩЕГО БИЗНЕСА")
    print("=" * 50)
    print()
    
    engine = create_async_engine(production_db_url, echo=False)
    async_session = async_sessionmaker(engine, expire_on_commit=False)
    
    async with async_session() as session:
        user_service = UserService(session)
        business_service = BusinessService(session)
        
        # Проверяем, не существует ли уже пользователь
        existing_user = await user_service.get_by_username(username)
        if existing_user:
            print(f"❌ Пользователь с логином '{username}' уже существует")
            return
        
        # Находим бизнес
        business = await business_service.get_by_slug(business_slug)
        if not business:
            print(f"❌ Бизнес с slug '{business_slug}' не найден")
            return
        
        print(f"✅ Найден бизнес: {business.name} (slug: {business.slug})")
        
        # Показываем текущего владельца
        stmt = select(User).where(User.id == business.owner_id)
        result = await session.execute(stmt)
        current_owner = result.scalar_one_or_none()
        if current_owner:
            print(f"   Текущий владелец: {current_owner.username or 'без логина'} (ID: {current_owner.id})")
        
        print()
        
        # Создаем нового пользователя
        print(f"👤 Создание пользователя '{username}'...")
        user = await user_service.create_user(
            username=username,
            password=password,
            email=email,
            role="owner",
        )
        print(f"✅ Пользователь создан (ID: {user.id})")
        
        # Назначаем нового пользователя владельцем бизнеса
        print(f"🏢 Назначение пользователя владельцем бизнеса...")
        business.owner_id = user.id
        await session.commit()
        await session.refresh(business)
        
        print(f"✅ Пользователь назначен владельцем бизнеса")
        
        print()
        print("=" * 50)
        print("✅ ПОЛЬЗОВАТЕЛЬ УСПЕШНО СОЗДАН И НАЗНАЧЕН ВЛАДЕЛЬЦЕМ!")
        print("=" * 50)
        print(f"   Логин: {username}")
        print(f"   Бизнес: {business.name} (slug: {business.slug})")
        print()
        print(f"   Теперь вы можете войти с логином: {username}")
        print("=" * 50)
    
    await engine.dispose()


async def main():
    parser = argparse.ArgumentParser(description='Создать пользователя для существующего бизнеса')
    parser.add_argument('--username', required=True, help='Логин пользователя')
    parser.add_argument('--password', required=True, help='Пароль пользователя')
    parser.add_argument('--business-slug', required=True, help='Slug существующего бизнеса')
    parser.add_argument('--email', help='Email пользователя (опционально)')
    
    args = parser.parse_args()
    
    await create_user_for_business(
        username=args.username,
        password=args.password,
        business_slug=args.business_slug,
        email=args.email,
    )


if __name__ == '__main__':
    asyncio.run(main())

