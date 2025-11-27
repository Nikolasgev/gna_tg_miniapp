# 🔍 Диагностика ошибки 502 на Railway

## Шаг 1: Проверьте логи в Railway

1. Зайдите в **Railway Dashboard**
2. Откройте ваш проект
3. Перейдите в **"Deployments"** или **"Logs"**
4. Откройте последний деплой
5. **Скопируйте логи** - там должна быть конкретная ошибка

---

## Шаг 2: Проверьте переменные окружения

В Railway Dashboard → ваш проект → **Variables** убедитесь, что есть:

### Обязательные:
- ✅ `DATABASE_URL` - должен быть автоматически создан
- ✅ `SECRET_KEY` - ваш секретный ключ
- ✅ `ENVIRONMENT=production`

### Важно для CORS:
- ✅ `CORS_ORIGINS` - должен содержать URL вашего фронтенда:
  ```
  ["https://web-mll71pc8p-nikolas-projects-72b2ba19.vercel.app"]
  ```

---

## Шаг 3: Типичные ошибки и решения

### Ошибка: "DATABASE_URL not found"
**Решение:** Добавьте PostgreSQL в Railway:
1. Railway Dashboard → ваш проект
2. "+ New" → "Database" → "PostgreSQL"
3. Railway автоматически создаст `DATABASE_URL`

### Ошибка: "Connection refused" или "Database connection failed"
**Решение:** 
- Проверьте, что PostgreSQL запущен
- Проверьте формат `DATABASE_URL`: должен быть `postgresql+asyncpg://...`

### Ошибка: "Module not found" или "Import error"
**Решение:**
- Проверьте, что все зависимости в `requirements.txt`
- Railway должен установить их автоматически

### Ошибка: "Port already in use"
**Решение:**
- Убедитесь, что используется `$PORT` (Railway устанавливает автоматически)
- Проверьте `railway.json` - там должна быть команда с `$PORT`

---

## Шаг 4: Проверьте формат переменных

### CORS_ORIGINS должен быть JSON массивом:
```
["https://web-mll71pc8p-nikolas-projects-72b2ba19.vercel.app"]
```

**НЕ так:**
```
https://web-mll71pc8p-nikolas-projects-72b2ba19.vercel.app
```

### DATABASE_URL должен быть в формате:
```
postgresql+asyncpg://user:password@host:port/database
```

---

## Шаг 5: Перезапустите деплой

Если изменили переменные окружения:
1. Railway Dashboard → ваш проект
2. "Deployments" → последний деплой
3. Нажмите "Redeploy" или сделайте новый push в GitHub

---

## Шаг 6: Проверьте railway.json

Убедитесь, что `railway.json` содержит:
```json
{
  "deploy": {
    "startCommand": "uvicorn app.main:app --host 0.0.0.0 --port $PORT"
  }
}
```

---

## Что делать дальше:

1. **Скопируйте логи из Railway** - там будет конкретная ошибка
2. **Проверьте переменные окружения** - все ли заполнены
3. **Проверьте, что PostgreSQL запущен** - в Railway Dashboard
4. **Попробуйте перезапустить** - Redeploy в Railway

---

## Если ничего не помогает:

Создайте минимальный тест:
1. Временно упростите `app/main.py` - уберите сложную логику
2. Оставьте только простой endpoint `/health`
3. Задеплойте и проверьте
4. Если работает - проблема в коде, если нет - проблема в конфигурации

