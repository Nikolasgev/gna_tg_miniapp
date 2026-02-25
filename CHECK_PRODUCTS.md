# Проверка товаров в production

## Статус

✅ **Товары в базе данных:** 30 товаров успешно мигрированы
✅ **Backend работает:** API доступен на https://gnatgminiapp-production.up.railway.app
⚠️ **Проблема:** Endpoint `/api/v1/products/{business_slug}/products` возвращает Internal Server Error

## Что проверить

### 1. Frontend (мини-приложение)
Frontend запущен с production API. Откройте браузер и проверьте:
- Каталог товаров отображается
- Товары загружаются из production базы

### 2. Админ-панель
Для проверки через админ-панель:
```bash
cd frontend
flutter run -d chrome --dart-define=API_BASE_URL=https://gnatgminiapp-production.up.railway.app --dart-define=ENVIRONMENT=production
```

### 3. Проверка через Railway Dashboard
1. Откройте https://railway.app/
2. Выберите проект `capable-tenderness`
3. Откройте сервис `gna_tg_miniapp`
4. Перейдите в "Deployments" → последний деплой → "View Logs"
5. Проверьте ошибки при запросе `/api/v1/products/default-business/products`

## Возможные причины ошибки

1. **Проблема с подключением к базе данных** - проверьте переменную `DATABASE_URL` в Railway
2. **Ошибка в коде API** - проверьте логи Railway
3. **Проблема с кешированием** - Redis может быть не настроен

## Быстрая проверка товаров в базе

Товары точно есть в базе (проверено):
- Эспрессо
- Капучино
- Латте
- Американо
- Чизкейк
- И еще 25 товаров

## Следующие шаги

1. Проверьте логи Railway для выявления ошибки
2. Убедитесь, что переменные окружения настроены правильно
3. Проверьте, что Redis работает (если используется кеширование)

