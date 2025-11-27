Ниже приведено **полное и структурированное ТЗ для backend-части**, уже **обновлённое с учётом решения использовать Firebase Authentication** и **исключения собственных JWT/refresh токенов**, а также учитывающее все элементы вашего первоначального ТЗ.

Тон — формальный, технический, пригодный для передачи разработчикам и менеджеру проекта.

---

# **Техническое задание (Backend) — Telegram Mini App Builder**

**Версия: 1.2 (с учётом Firebase Authentication)**
**Стек: FastAPI + PostgreSQL + Redis + Firebase Auth**

---

# **1. Цель системы**

Создать серверную часть для конструктора Telegram Mini App, обеспечивающего:

1. Публичный API для клиента Mini App (каталог, корзина, заказ, оплата).
2. Административный API для владельцев/сотрудников бизнеса (управление товарами, заказами и настройками).
3. Интеграцию с платёжными провайдерами (Stripe/YooKassa).
4. Интеграцию с Telegram WebApp (валидация `init_data`).
5. Централизованную аутентификацию владельцев/сотрудников через **Firebase Authentication**.

---

# **2. Технологический стек**

## 2.1 Основные компоненты

* **Python 3.11+**
* **FastAPI** (ASGI REST backend)
* **Uvicorn** (в продакшене — Uvicorn+Gunicorn)
* **PostgreSQL 15+**
* **Redis** (кэш, фоновые задачи)
* **SQLAlchemy 2.x (async)**
* **asyncpg**
* **Alembic**
* **Firebase Authentication** (аутентификация владельцев и сотрудников)
* **Telegram WebApp init_data validation** (аутентификация клиентов)
* **Stripe / YooKassa** (оплата)
* **Dramatiq + Redis** (или FastAPI BackgroundTasks на MVP)
* **Docker / docker-compose**
* **GitHub Actions** (CI/CD)
* **Sentry** (ошибки)
* **Prometheus + Grafana** (опционально)

---

# **3. Архитектура системы**

## 3.1 Общая схема

1. **Admin Web Panel** → Firebase Login → отправляет на Backend ID Token.
2. **Backend** проверяет токен через Firebase Admin SDK → находит/создаёт пользователя в PostgreSQL.
3. **Mini App Client** → отправляет `init_data` → Backend валидирует подпись → возвращает профиль telegram-пользователя.
4. Заказы — PostgreSQL → Payments — внешние провайдеры → Webhooks → Backend.
5. Notification — через Telegram Bot API (фоновые задачи в Dramatiq).

## 3.2 Принципы

* Stateless REST API.
* Firebase ID Token = единственный источник истины для аутентификации owner/staff.
* Telegram init_data = источник истины для клиентов Mini App.
* Все бизнес-данные (каталог, заказы) хранятся в PostgreSQL.
* Асинхронные обработчики для оплаты и уведомлений.

---

# **4. Модель данных (PostgreSQL)**

Все таблицы используют `uuid` как PK. Все временные поля — `timestamptz`.

## 4.1 Таблица `users`

```
id                uuid PK
firebase_uid      varchar unique nullable
telegram_id       bigint unique nullable
email             varchar unique nullable
role              varchar NOT NULL  -- superadmin / owner / staff / client
created_at        timestamptz
updated_at        timestamptz
last_login        timestamptz
```

Примечания:

* Владельцы и сотрудники определяются по `firebase_uid`.
* Клиенты Mini App — по `telegram_id`.
* Один пользователь может иметь только один тип идентификации.

---

## 4.2 Таблица `businesses`

```
id          uuid PK
owner_id    uuid FK -> users.id
name        varchar
slug        varchar unique
description text
timezone    varchar
created_at  timestamptz
updated_at  timestamptz
```

---

## 4.3 Таблица `products`

```
id          uuid PK
business_id uuid FK -> businesses.id (index)
title       varchar
description text
price       numeric(10,2)
currency    varchar(3) default 'RUB'
sku         varchar nullable
image_url   varchar nullable
is_active   boolean default TRUE
created_at  timestamptz
updated_at  timestamptz
```

---

## 4.4 Таблица `categories`

```
id          uuid PK
business_id uuid FK
name        varchar
position    int
created_at  timestamptz
updated_at  timestamptz
```

---

## 4.5 Таблица `product_categories` (M2M)

```
product_id   uuid FK
category_id  uuid FK
PRIMARY KEY (product_id, category_id)
```

---

## 4.6 Таблица `orders`

```
id                uuid PK
business_id       uuid FK
user_telegram_id  bigint nullable
customer_name     varchar
customer_phone    varchar
customer_address  text nullable
total_amount      numeric(10,2)
currency          varchar (default from business)
status            varchar  -- new / accepted / preparing / ready / cancelled / completed
payment_status    varchar  -- pending / paid / failed / refunded
payment_method    varchar  -- cash / online
metadata          jsonb
created_at        timestamptz
updated_at        timestamptz
```

---

## 4.7 Таблица `order_items`

```
id            uuid PK
order_id      uuid FK
product_id    uuid FK
title_snapshot varchar
quantity      int
unit_price    numeric(10,2)
total_price   numeric(10,2)
```

---

## 4.8 Таблица `payments`

```
id                  uuid PK
order_id            uuid FK
provider            varchar   -- stripe / yookassa
provider_payment_id varchar
amount              numeric
status              varchar
raw_payload         jsonb
created_at          timestamptz
```

---

## 4.9 Таблица `settings`

```
id           uuid PK
business_id  uuid FK
key          varchar
value        jsonb
```

---

## 4.10 Таблица `webhooks_log`

```
id            uuid PK
event_type    varchar
payload       jsonb
response_code int
created_at    timestamptz
```

---

# **5. API (контракт)**

## 5.1 Правила аутентификации

### 5.1.1 Admin API

Требует заголовок:

```
Authorization: Bearer <Firebase ID Token>
```

Backend:

* Проверяет токен через Firebase Admin SDK.
* Ищет пользователя по `firebase_uid`.
* Проверяет роль (`owner`, `staff`, `superadmin`).

### 5.1.2 Client API (Mini App)

* Получает `init_data` от Telegram.
* Отправляет его на `/api/v1/telegram/validate_init_data`.
* Backend валидирует подпись (SHA256 HMAC + BOT_TOKEN).

---

## 5.2 Endpoints

### 5.2.1 Аутентификация

**POST /api/v1/telegram/validate_init_data**
Проверка init_data.

Запрос:

```
{ "init_data": "<string>" }
```

Ответ:

```
{
  "ok": true,
  "telegram_user": {
    "id": 123,
    "first_name": "...",
    "username": "..."
  }
}
```

---

### 5.2.2 Business

**GET /api/v1/businesses/{slug}**
Публичная информация.

**POST /api/v1/businesses** (только owner / superadmin)
Создание бизнеса.

---

### 5.2.3 Products / Categories

**GET /api/v1/businesses/{slug}/products**
Параметры:

```
?category=uuid
?q=string
&page=int
&limit=int
```

**GET /api/v1/businesses/{slug}/products/{id}**

**POST /api/v1/businesses/{id}/products**
Только `owner`/`staff`.

**PUT /api/v1/products/{id}**

**DELETE /api/v1/products/{id}**

**GET /api/v1/businesses/{id}/categories**

**POST /api/v1/businesses/{id}/categories**

---

### 5.2.4 Orders & Checkout

**POST /api/v1/businesses/{slug}/orders**

Запрос:

```
{
  "customer_name": "Иван",
  "customer_phone": "+7...",
  "customer_address": "ул. ...",
  "items": [
    { "product_id": "...", "quantity": 2, "note": "" }
  ],
  "payment_method": "online" | "cash"
}
```

Ответ (online):

```
{
  "order_id": "uuid",
  "payment": {
    "provider": "stripe",
    "checkout_url": "https://..."
  }
}
```

**GET /api/v1/orders/{id}**

**POST /api/v1/orders/{id}/cancel**

**POST /api/v1/orders/{id}/status**
Запрос:

```
{ "status": "preparing" }
```

---

### 5.2.5 Payments Webhooks

**POST /api/v1/payments/webhook/stripe**

**POST /api/v1/payments/webhook/yookassa**

Требования:

* Подпись webhook обязательно валидируется.
* В систему заносится запись в `webhooks_log`.
* Обновляется `orders.payment_status`.

---

### 5.2.6 Mini App Config

**GET /api/v1/businesses/{slug}/config**
Возвращает:

* theme
* logo
* currency
* working_hours

---

# **6. Бизнес-логика**

## 6.1 Создание заказа

1. Backend получает заказ.
2. Валидирует товары и их активность.
3. Перечитывает цены из БД.
4. Вычисляет итоговую сумму (не доверять данным клиента).
5. Создаёт запись `order` со статусом:

   * `status = "new"`
   * `payment_status = "pending"`
6. Если оплата online:

   * создаёт платеж у провайдера,
   * возвращает `checkout_url`.

---

## 6.2 Обработка оплаты

1. Провайдер вызывает webhook.
2. Backend проверяет подпись.
3. Обновляет `payments.status`.
4. Изменяет `orders.payment_status = "paid"`.
5. Отправляет уведомление владельцу бизнеса (через Telegram Bot).

---

## 6.3 Работа ролей

| Роль           | Доступ                         |
| -------------- | ------------------------------ |
| **superadmin** | Полный доступ ко всем бизнесам |
| **owner**      | Полный доступ к своему бизнесу |
| **staff**      | CRUD товаров, заказов          |
| **client**     | Только действия в Mini App     |

---

# **7. Безопасность**

* Firebase ID Token — единственный метод аутентификации админов.
* Telegram init_data — единственный метод аутентификации клиентов.
* Проверка всех входных данных Pydantic.
* HTTPS обязательно.
* Rate-limit: 30 req/min на IP для создания заказа.
* Валидация webhook-подписей (Stripe/YooKassa).
* CORS — только разрешённые домены.
* SQL-инъекции исключаются использованием SQLAlchemy async.
* Логи в JSON (structlog).
* Sensitive данные никогда не логируются.

---

# **8. Производительность**

* Пиковая нагрузка: до 1000 req/min.
* Connection pool PostgreSQL: 20–30 подключений.
* Кэширование Redis:

  * `GET /products` — TTL 30 сек.
  * `GET /config` — TTL 1 мин.
* Пагинация — ограничение по умолчанию: `limit = 20`.

---

# **9. Инфраструктура**

## 9.1 Docker

Обязательные контейнеры:

* backend
* postgres
* redis

Опционально:

* nginx (reverse proxy)
* prometheus
* grafana

## 9.2 Переменные окружения

```
DATABASE_URL
REDIS_URL
SECRET_KEY

FIREBASE_PROJECT_ID
FIREBASE_CLIENT_EMAIL
FIREBASE_PRIVATE_KEY

STRIPE_SECRET_KEY
STRIPE_WEBHOOK_SECRET

YOOKASSA_TOKEN
YOOKASSA_WEBHOOK_SECRET

TELEGRAM_BOT_TOKEN
CORS_ORIGINS
SENTRY_DSN
```

---

# **10. Тестирование**

## 10.1 Unit-тесты

* бизнес-логика заказов
* перерасчёт стоимости
* категории и фильтры

## 10.2 Integration tests

* webhook оплаты
* миграции БД
* мини-endpointы каталога

## 10.3 End-to-End

* создать бизнес → создать товар → заказать → имитация оплаты → статус «paid»

Порог покрытия критической логики: **≥ 70%**.

---

# **11. CI/CD**

GitHub Actions:

1. Линтеры: black, isort, flake8
2. Pytest
3. Сборка Docker-образа
4. Push в container registry
5. Деплой:

   * автоматический для staging
   * ручное подтверждение для production

---

# **12. Acceptance Criteria (итоговые)**

1. Backend реализует все описанные endpoint’ы.
2. Firebase Authentication полностью работает для owner/staff.
3. Telegram init_data корректно валидируется.
4. Создание заказа всегда использует свежие цены из БД.
5. Webhook оплаты корректно обновляет заказ.
6. Админ может управлять товарами, категориями и заказами.
7. Mini App функционирует без ошибок.
8. Sentry собирает исключения.
9. OpenAPI документация доступна по `/docs`.
10. Критические тесты покрыты на ≥ 70%.

---
