# ✅ Чек-лист настройки Railway

## Системные переменные (автоматические) ✅
Railway автоматически предоставляет эти переменные - ничего настраивать не нужно:
- `RAILWAY_PUBLIC_DOMAIN`
- `RAILWAY_PRIVATE_DOMAIN`
- `RAILWAY_PROJECT_NAME`
- `RAILWAY_ENVIRONMENT_NAME`
- `RAILWAY_SERVICE_NAME`
- `RAILWAY_PROJECT_ID`
- `RAILWAY_ENVIRONMENT_ID`
- `RAILWAY_SERVICE_ID`
- **`PORT`** - ⚠️ ВАЖНО! Railway автоматически устанавливает порт

---

## Пользовательские переменные (нужно добавить вручную)

В Railway Dashboard → ваш проект → Variables добавьте:

### Обязательные:
- [ ] `DATABASE_URL` - должен быть автоматически создан при добавлении PostgreSQL
- [ ] `SECRET_KEY` - ваш секретный ключ (минимум 32 символа)
- [ ] `ENVIRONMENT=production`
- [ ] `ADMIN_PASSWORD` - пароль для админ-панели

### Telegram:
- [ ] `TELEGRAM_BOT_TOKEN` - токен вашего Telegram бота

### CORS (важно для фронтенда!):
- [ ] `CORS_ORIGINS=["https://web-mll71pc8p-nikolas-projects-72b2ba19.vercel.app"]`
  - Или ваш кастомный домен, если есть

### Платежи (YooKassa):
- [ ] `YOOKASSA_SHOP_ID`
- [ ] `YOOKASSA_SECRET_KEY`
- [ ] `YOOKASSA_WEBHOOK_SECRET`

### Доставка (Яндекс.Доставка):
- [ ] `YANDEX_DELIVERY_TOKEN`

### Адреса (DaData):
- [ ] `DADATA_API_KEY`

### Опционально:
- [ ] `REDIS_URL` - если используете Redis (создается автоматически при добавлении Redis)

---

## Проверка после настройки:

1. **Проверьте, что изменения запушены:**
   ```bash
   cd /Users/nikolasgevorkan/GNA_tg_store/backend
   git push origin main
   ```

2. **Проверьте деплой в Railway:**
   - Railway Dashboard → ваш проект → Deployments
   - Последний деплой должен быть успешным

3. **Проверьте логи:**
   - Railway Dashboard → ваш проект → Logs
   - Должны быть логи запуска приложения

4. **Проверьте health endpoint:**
   ```bash
   curl https://gnatgminiapp-production.up.railway.app/health
   ```
   Должно вернуть: `{"status":"ok"}`

---

## Если всё ещё ошибка 502:

1. Проверьте логи в Railway - там должна быть конкретная ошибка
2. Убедитесь, что PostgreSQL запущен и доступен
3. Проверьте, что все обязательные переменные окружения заполнены
4. Убедитесь, что `PORT` используется в коде (Railway устанавливает автоматически)

