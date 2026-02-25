# Руководство по новой системе авторизации админки

## Что изменилось

Админка теперь поддерживает **множественных пользователей**. Каждый владелец бизнеса входит по своему **логину и паролю** и видит только **свой бизнес**.

## Как это работает

### 1. Вход в админку

1. Откройте админ-панель
2. Введите **логин** (username) и **пароль**
3. После успешного входа вы увидите только свой бизнес

### 2. Создание нового пользователя

Для создания нового владельца бизнеса используйте скрипт:

```bash
cd backend
source venv/bin/activate
export DATABASE_URL="postgresql://user:password@host:5432/dbname"
python create_admin_user.py \
  --username newuser \
  --password securepassword123 \
  --business-name "Название магазина" \
  --business-slug unique-slug \
  --email user@example.com
```

### 3. Настройка существующего пользователя

Если у вас уже есть бизнес в базе, но нет пользователя с логином/паролем:

```bash
cd backend
source venv/bin/activate
export DATABASE_URL="postgresql://user:password@host:5432/dbname"
python setup_existing_user.py \
  --username admin \
  --password password123 \
  --business-slug default-business
```

## Текущие учетные данные

Для существующего бизнеса `default-business`:
- **Логин:** `admin`
- **Пароль:** `admin123`

⚠️ **Важно:** Смените пароль после первого входа!

## Регистрация через API

Также можно зарегистрировать нового пользователя через API:

```bash
curl -X POST https://your-backend-url.com/api/v1/admin/register \
  -H "Content-Type: application/json" \
  -d '{
    "username": "newuser",
    "password": "securepassword123",
    "email": "user@example.com",
    "business_name": "Название магазина",
    "business_slug": "unique-slug"
  }'
```

## Безопасность

- Пароли хранятся в хешированном виде (bcrypt)
- Каждый пользователь видит только свой бизнес
- JWT токен содержит информацию о бизнесе пользователя
- Токен автоматически добавляется ко всем запросам

## Что дальше

1. Войдите в админку с логином `admin` и паролем `admin123`
2. Смените пароль через настройки (если есть такая функция)
3. Создайте дополнительные пользователи для других бизнесов при необходимости

