# Чеклист: полностью рабочее приложение

Краткий порядок действий и ссылки на детали.

## 1. Railway (backend)

- [ ] `DATABASE_URL`, `REDIS_URL`, `SECRET_KEY`, `ADMIN_PASSWORD`, `ENVIRONMENT=production`
- [ ] `TELEGRAM_BOT_TOKEN` — **обязателен** для Mini App (валидация initData) и уведомлений о заказах
- [ ] `CORS_ORIGINS` — включить origin фронта. Для GitHub Pages:
  ```json
  ["https://nikolasgev.github.io"]
  ```
  или вместе с API:
  ```json
  ["https://nikolasgev.github.io","https://gnatgminiapp-production.up.railway.app"]
  ```
  Если переменная **не** задана, используются значения по умолчанию из кода ([backend/app/config.py](../backend/app/config.py)).
- [ ] Миграции: `alembic upgrade head` (см. [backend/RAILWAY_VARIABLES_SETUP.md](../backend/RAILWAY_VARIABLES_SETUP.md))
- [ ] Логи деплоя без ошибок подключения к БД/Redis

Проверка с машины разработчика:

```bash
chmod +x scripts/check_production_readiness.sh
./scripts/check_production_readiness.sh
```

## 2. GitHub Pages (frontend)

- [ ] Репозиторий `gna-tg-miniapp-store-frontend`: **Settings → Pages → Source: GitHub Actions**
- [ ] Workflow **Deploy to GitHub Pages** успешно завершён
- [ ] URL Mini App (пример): `https://nikolasgev.github.io/gna-tg-miniapp-store-frontend/`

## 3. @BotFather

- [ ] Создан бот (`/newbot`)
- [ ] Mini App: **Web App URL** = полный HTTPS URL фронта (со слэшем в конце по желанию, главное — рабочая страница)
- [ ] В чате с ботом пользователь нажал **Start** или `/start` — иначе личные уведомления о заказе могут не дойти

Подробнее: [TELEGRAM_BOT_SETUP.md](../TELEGRAM_BOT_SETUP.md)

## 4. Опционально: polling-бот на Railway

Если нужны ответы на `/start` в ЛС без ручных сценариев — второй сервис с `python run_telegram_bot.py`: [docs/RAILWAY_TELEGRAM_WORKER.md](RAILWAY_TELEGRAM_WORKER.md)

## 5. Хостинг фронта (решение)

См. [docs/HOSTING.md](HOSTING.md) — сравнение GitHub Pages / Vercel / Yandex Cloud.

## 6. Финальный прогон

1. Открыть бота в Telegram → кнопка Mini App
2. Каталог, корзина, оформление (по возможности тестовый заказ)
3. В DevTools: нет ошибок CORS на запросы к Railway
