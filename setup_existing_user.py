#!/usr/bin/env python3
"""
Скрипт для настройки существующего пользователя (добавление username и password).

Использование:
    export DATABASE_URL="postgresql://user:password@host:5432/dbname"
    python setup_existing_user.py --username admin --password password123
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
from app.core.security import get_password_hash


async def setup_existing_user(
    username: str,
    password: str,
    business_slug: str = 'default-business',
):
    """Настроить существующего пользователя (владельца бизнеса)."""
    production_db_url = os.getenv('DATABASE_URL')
    
    if not production_db_url:
        print("❌ Ошибка: DATABASE_URL не установлен")
        sys.exit(1)
    
    # Конвертируем postgresql:// в postgresql+asyncpg:// если нужно
    if not production_db_url.startswith('postgresql+asyncpg://'):
        if production_db_url.startswith('postgresql://'):
            production_db_url = production_db_url.replace('postgresql://', 'postgresql+asyncpg://', 1)
    
    print("=" * 50)
    print("👤 НАСТРОЙКА СУЩЕСТВУЮЩЕГО ПОЛЬЗОВАТЕЛЯ")
    print("=" * 50)
    print()
    
    engine = create_async_engine(production_db_url, echo=False)
    async_session = async_sessionmaker(engine, expire_on_commit=False)
    
    async with async_session() as session:
        # Находим бизнес
        from app.services.business_service import BusinessService
        business_service = BusinessService(session)
        business = await business_service.get_by_slug(business_slug)
        
        if not business:
            print(f"❌ Бизнес с slug '{business_slug}' не найден")
            return
        
        # Находим владельца бизнеса
        stmt = select(User).where(User.id == business.owner_id)
        result = await session.execute(stmt)
        user = result.scalar_one_or_none()
        
        if not user:
            print(f"❌ Пользователь с ID {business.owner_id} не найден")
            return
        
        # Проверяем, не занят ли username
        if user.username and user.username != username:
            stmt = select(User).where(User.username == username)
            result = await session.execute(stmt)
            existing_user = result.scalar_one_or_none()
            if existing_user:
                print(f"❌ Пользователь с логином '{username}' уже существует")
                return
        
        # Обновляем пользователя
        print(f"👤 Обновление пользователя (ID: {user.id})...")
        user.username = username
        user.password_hash = get_password_hash(password)
        user.role = "owner"
        
        await session.commit()
        await session.refresh(user)
        
        print(f"✅ Пользователь обновлен:")
        print(f"   Логин: {user.username}")
        print(f"   Роль: {user.role}")
        print(f"   Бизнес: {business.name} (slug: {business.slug})")
        print()
        print("=" * 50)
        print("✅ НАСТРОЙКА ЗАВЕРШЕНА!")
        print("=" * 50)
        print(f"   Теперь вы можете войти с логином: {username}")
        print("=" * 50)
    
    await engine.dispose()


async def main():
    parser = argparse.ArgumentParser(description='Настроить существующего пользователя')
    parser.add_argument('--username', required=True, help='Логин пользователя')
    parser.add_argument('--password', required=True, help='Пароль пользователя')
    parser.add_argument('--business-slug', default='default-business', help='Slug бизнеса')
    
    args = parser.parse_args()
    
    await setup_existing_user(
        username=args.username,
        password=args.password,
        business_slug=args.business_slug,
    )


if __name__ == '__main__':
    asyncio.run(main())

