#!/bin/bash
# Простой скрипт для миграции товаров в production

echo "🔄 Миграция товаров из локальной БД в production"
echo ""

# Проверяем, что DATABASE_URL установлен
if [ -z "$DATABASE_URL" ]; then
    echo "❌ DATABASE_URL не установлен"
    echo ""
    echo "Получите DATABASE_URL из Railway Dashboard:"
    echo "  1. Откройте https://railway.app/"
    echo "  2. Выберите ваш проект"
    echo "  3. Откройте PostgreSQL сервис"
    echo "  4. Перейдите в 'Connect' или 'Variables'"
    echo "  5. Скопируйте 'Postgres Connection URL'"
    echo ""
    echo "Затем запустите:"
    echo "  export DATABASE_URL='postgresql://user:password@host:5432/dbname'"
    echo "  ./migrate_products_simple.sh"
    echo ""
    echo "Или запустите напрямую:"
    echo "  export DATABASE_URL='postgresql://...'"
    echo "  python migrate_products_to_production.py"
    exit 1
fi

echo "✅ DATABASE_URL установлен"
echo ""

# Активируем виртуальное окружение
if [ -d "venv" ]; then
    source venv/bin/activate
    echo "✅ Виртуальное окружение активировано"
fi

# Запускаем скрипт миграции
echo "🚀 Запуск миграции..."
echo ""
python migrate_products_to_production.py
