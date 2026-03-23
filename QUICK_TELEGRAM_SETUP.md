# Быстрый запуск для тестирования в Telegram

## Что нужно

1. **ngrok** - для создания HTTPS туннеля
2. **Telegram бот** - создается через @BotFather

Для локальной отладки Mini App рекомендуется **ngrok** (скрипты `start_for_telegram.sh`, `start_for_telegram_ngrok.sh`, `start_for_telegram_single.sh`). При необходимости можно использовать альтернативы из репозитория (`start_for_telegram_serveo.sh`, `start_for_telegram_localhostrun.sh`). Сценарий **LocalTunnel** из репозитория удалён как избыточный.

## Шаг 1: Установка ngrok

```bash
# macOS
brew install ngrok

# Или скачайте с https://ngrok.com/download
```

## Шаг 2: Регистрация в ngrok

1. Зайдите на https://ngrok.com
2. Зарегистрируйтесь (бесплатно)
3. Получите токен авторизации на https://dashboard.ngrok.com/get-started/your-authtoken
4. Авторизуйтесь:
   ```bash
   ngrok config add-authtoken YOUR_TOKEN
   ```

## Шаг 3: Создание Telegram бота

1. Откройте [@BotFather](https://t.me/BotFather) в Telegram
2. Отправьте `/newbot`
3. Следуйте инструкциям:
   - Имя бота: например "Мой Магазин"
   - Username: например `my_shop_bot` (должен заканчиваться на `bot`)
4. Сохраните токен бота (понадобится позже)

## Шаг 4: Запуск приложения

Просто выполните:

```bash
./start_for_telegram.sh
```

Скрипт автоматически:
- ✅ Запустит backend
- ✅ Запустит ngrok для backend
- ✅ Соберет frontend с правильным API URL
- ✅ Запустит frontend
- ✅ Запустит ngrok для frontend
- ✅ Покажет вам URL для настройки в BotFather

## Шаг 5: Настройка в BotFather

1. Откройте @BotFather в Telegram
2. Отправьте `/newapp`
3. Выберите вашего бота
4. Заполните:
   - **Title:** Название магазина
   - **Short name:** Короткое имя
   - **Description:** Описание
   - **Web App URL:** Скопируйте URL из вывода скрипта (Frontend URL)

## Готово! 🎉

Теперь:
1. Найдите вашего бота в Telegram
2. Откройте бота
3. Нажмите кнопку "Open" или отправьте `/start`
4. Mini App откроется!

---

## Если что-то не работает

### ngrok не запускается
- Проверьте авторизацию: `ngrok config check`
- Убедитесь, что токен правильный

### Backend не запускается
- Проверьте, что PostgreSQL запущен
- Проверьте переменные окружения в `.env`

### Frontend не собирается
- Убедитесь, что Flutter установлен: `flutter doctor`
- Проверьте зависимости: `cd frontend && flutter pub get`

### URL не работает в Telegram
- Убедитесь, что URL начинается с `https://`
- Проверьте, что ngrok туннель активен (откройте http://localhost:4040)
- Убедитесь, что URL скопирован правильно в BotFather

---

## Остановка

Нажмите `Ctrl+C` в терминале, где запущен скрипт. Все процессы остановятся автоматически.
