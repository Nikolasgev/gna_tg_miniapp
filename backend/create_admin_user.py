#!/usr/bin/env python3
"""
Скрипт для создания пользователя-владельца бизнеса.

Использование:
    export DATABASE_URL="postgresql://user:password@host:5432/dbname"
    python create_admin_user.py --username admin --password password123 --business-name "Мой магазин" --business-slug default-business
"""
import asyncio
import os
import sys
import argparse
import uuid

from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker
from sqlalchemy import select

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from app.models.user import User
from app.models.business import Business
from app.services.user_service import UserService
from app.services.business_service import BusinessService


async def create_admin_user(
    username: str,
    password: str,
    business_name: str,
    business_slug: str,
    email: str | None = None,
):
    """Создать пользователя-владельца бизнеса."""
    production_db_url = os.getenv('DATABASE_URL')
    
    if not production_db_url:
        print("❌ Ошибка: DATABASE_URL не установлен")
        sys.exit(1)
    
    # Конвертируем postgresql:// в postgresql+asyncpg:// если нужно
    if not production_db_url.startswith('postgresql+asyncpg://'):
        if production_db_url.startswith('postgresql://'):
            production_db_url = production_db_url.replace('postgresql://', 'postgresql+asyncpg://', 1)
    
    print("=" * 50)
    print("👤 СОЗДАНИЕ ПОЛЬЗОВАТЕЛЯ-ВЛАДЕЛЬЦА БИЗНЕСА")
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
        
        # Проверяем, не существует ли уже бизнес
        existing_business = await business_service.get_by_slug(business_slug)
        if existing_business:
            print(f"❌ Бизнес с slug '{business_slug}' уже существует")
            return
        
        # Создаем пользователя
        print(f"👤 Создание пользователя '{username}'...")
        user = await user_service.create_user(
            username=username,
            password=password,
            email=email,
            role="owner",
        )
        print(f"✅ Пользователь создан (ID: {user.id})")
        
        # Создаем бизнес
        print(f"🏢 Создание бизнеса '{business_name}'...")
        business = await business_service.create(
            owner_id=user.id,
            name=business_name,
            slug=business_slug,
            description=None,
        )
        print(f"✅ Бизнес создан (ID: {business.id}, slug: {business.slug})")
        
        print()
        print("=" * 50)
        print("✅ ПОЛЬЗОВАТЕЛЬ И БИЗНЕС УСПЕШНО СОЗДАНЫ!")
        print("=" * 50)
        print(f"   Логин: {username}")
        print(f"   Бизнес: {business_name} (slug: {business_slug})")
        print("=" * 50)
    
    await engine.dispose()


async def main():
    parser = argparse.ArgumentParser(description='Создать пользователя-владельца бизнеса')
    parser.add_argument('--username', required=True, help='Логин пользователя')
    parser.add_argument('--password', required=True, help='Пароль пользователя')
    parser.add_argument('--business-name', required=True, help='Название бизнеса')
    parser.add_argument('--business-slug', required=True, help='Slug бизнеса (уникальный идентификатор)')
    parser.add_argument('--email', help='Email пользователя (опционально)')
    
    args = parser.parse_args()
    
    await create_admin_user(
        username=args.username,
        password=args.password,
        business_name=args.business_name,
        business_slug=args.business_slug,
        email=args.email,
    )


if __name__ == '__main__':
    asyncio.run(main())

