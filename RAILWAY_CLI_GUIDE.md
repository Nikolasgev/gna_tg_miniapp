# Руководство по использованию Railway CLI

## Установка (уже выполнено ✅)

Railway CLI установлен через Homebrew.

## Первые шаги

### 1. Войти в Railway

```bash
railway login
```

Эта команда откроет браузер для авторизации через GitHub.

### 2. Подключиться к проекту

```bash
cd backend
railway link
```

Выберите ваш проект `gna_tg_miniapp` из списка.

### 3. Проверить подключение

```bash
railway status
```

Должен показать информацию о текущем проекте.

## Полезные команды

### Просмотр переменных окружения

```bash
railway variables
```

### Установка переменной окружения

```bash
railway variables set SECRET_KEY="ваш_ключ"
railway variables set ADMIN_PASSWORD="ваш_пароль"
railway variables set CORS_ORIGINS='["*"]'
```

### Выполнение команд в контексте проекта

```bash
# Применить миграции
railway run alembic upgrade head

# Запустить скрипт миграции товаров
railway run python migrate_products_to_production.py

# Запустить Python скрипт
railway run python your_script.py
```

### Просмотр логов

```bash
railway logs
```

### Просмотр информации о проекте

```bash
railway status
railway whoami
```

## Миграция товаров в production

После подключения к проекту:

```bash
cd backend
railway link  # если еще не подключен
railway run python migrate_products_to_production.py
```

Railway автоматически подставит `DATABASE_URL` из переменных окружения проекта.

## Дополнительная информация

- Документация: https://docs.railway.com/guides/cli
- Помощь: `railway --help`
- Справка по команде: `railway <команда> --help`

