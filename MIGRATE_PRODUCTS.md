# Инструкция по переносу товаров в production

## Шаг 1: Убедитесь, что локальная БД запущена

```bash
cd backend
docker-compose up -d postgres
```

Проверьте, что PostgreSQL запущен:
```bash
docker ps | grep postgres
```

## Шаг 2: Получите DATABASE_URL для production из Railway Dashboard

1. Откройте https://railway.app/
2. Выберите ваш проект `gna_tg_miniapp`
3. Найдите сервис **PostgreSQL** в списке сервисов
4. Откройте его
5. Перейдите в раздел **"Connect"** или **"Variables"**
6. Найдите **"Postgres Connection URL"** или **"DATABASE_URL"**
7. Скопируйте URL (формат: `postgresql://user:password@host:5432/dbname`)

**Важно:** URL должен начинаться с `postgresql://` (скрипт автоматически добавит `+asyncpg`)

## Шаг 3: Запустите миграцию

### Вариант А: Через скрипт (проще)

```bash
cd backend
export DATABASE_URL="postgresql://user:password@host:5432/dbname"  # Вставьте ваш URL
./migrate_products_simple.sh
```

### Вариант Б: Напрямую через Python

```bash
cd backend
source venv/bin/activate
export DATABASE_URL="postgresql://user:password@host:5432/dbname"  # Вставьте ваш URL
python migrate_products_to_production.py
```

## Шаг 4: Проверьте результат

После выполнения скрипта вы увидите:
- ✅ Сколько товаров создано
- ⏭️  Сколько пропущено (уже существовали)
- ❌ Сколько ошибок

## Что делает скрипт:

1. ✅ Подключается к локальной БД (`localhost:5432`)
2. ✅ Получает все активные товары с категориями
3. ✅ Подключается к production БД на Railway
4. ✅ Находит бизнес по slug (по умолчанию `default-business`)
5. ✅ Создает товары в production БД
6. ✅ Связывает товары с категориями (если они существуют в production)
7. ✅ Сохраняет все данные: цены, скидки, изображения, вариации, stock_quantity

## Важно:

- Товары создаются с теми же ID, что и в локальной БД
- Если товар с таким ID уже существует, он пропускается
- Категории должны существовать в production БД (иначе они не будут связаны)
- Изображения должны быть доступны по тем же URL или загружены на production сервер

## Если нужно указать другой business_slug:

```bash
export BUSINESS_SLUG="your-business-slug"
export DATABASE_URL="postgresql://..."
python migrate_products_to_production.py
```

## Альтернативный способ (если Railway CLI подключен):

Если вы уже выполнили `railway link` в папке backend, можно попробовать:

```bash
cd backend
railway run bash -c "export DATABASE_URL=\$DATABASE_URL && python migrate_products_to_production.py"
```

Но проще всего получить DATABASE_URL из Dashboard и запустить локально.
