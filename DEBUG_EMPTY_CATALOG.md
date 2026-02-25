# Диагностика пустого каталога

## Проверка 1: Backend работает
```bash
curl http://localhost:8000/api/v1/products/default-business/products
```
Должен вернуть список продуктов (12 продуктов найдено).

## Проверка 2: Правильный API URL в приложении

При запуске приложения убедитесь, что передается правильный API_BASE_URL:
```bash
cd frontend
flutter run -d chrome \
  --dart-define=API_BASE_URL=http://localhost:8000 \
  --target=lib/mini_app/main.dart
```

## Проверка 3: Консоль браузера

Откройте DevTools (F12) и проверьте:
1. **Console** - есть ли ошибки?
2. **Network** - выполняются ли запросы к `/api/v1/products/default-business/products`?
3. **Network** - какой статус у запросов? (должен быть 200)

## Возможные проблемы:

### 1. CORS ошибка
Если в консоли видите CORS ошибку, нужно настроить CORS на backend.

### 2. Неправильный baseUrl
Проверьте в консоли браузера, какой baseUrl используется:
- Откройте DevTools → Console
- Введите: `AppConfig.baseUrl` (если доступно)
- Или проверьте Network tab - какой URL используется для запросов

### 3. Продукты не загружаются
Проверьте логи в консоли:
- Ищите сообщения с `CatalogBloc`
- Ищите сообщения с `LoadProducts`
- Ищите ошибки `DioException`

### 4. Продукты загружаются, но не отображаются
Проверьте состояние в CatalogBloc:
- Откройте DevTools → Flutter Inspector
- Проверьте состояние CatalogBloc
- Проверьте, есть ли продукты в состоянии

## Быстрое решение:

1. **Очистите кеш браузера** (Ctrl+Shift+Delete)
2. **Перезапустите приложение** с правильным API_BASE_URL
3. **Проверьте консоль** на наличие ошибок

## Проверка через API напрямую:

```bash
# Проверка бизнеса
curl http://localhost:8000/api/v1/businesses/default-business

# Проверка продуктов
curl http://localhost:8000/api/v1/products/default-business/products | python3 -m json.tool

# Проверка категорий
curl http://localhost:8000/api/v1/categories/default-business/categories | python3 -m json.tool
```

Все эти запросы должны возвращать данные.
