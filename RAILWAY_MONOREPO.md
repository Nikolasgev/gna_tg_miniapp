# Railway: монорепо и Mini App на том же домене

Репозиторий на GitHub: [Nikolasgev/gna_tg_miniapp](https://github.com/Nikolasgev/gna_tg_miniapp) (корень = монорепо: `backend/`, `frontend/`, …).

## 1. Root Directory = `backend`

В Railway: **сервис** → **Settings** → **Build**:

- **Root Directory**: `backend`  
  Иначе Docker соберётся из корня репозитория и не найдёт `app.main:app` и `Dockerfile` там, где ожидается.

- **Dockerfile path**: `Dockerfile` (относительно Root Directory, т.е. `backend/Dockerfile`).

После смены настроек сделайте **Redeploy**.

## 2. Что попадает в образ

В образ копируется содержимое `backend/`, включая **`backend/static_mini_app/`** (собранный Flutter Web). Сборка: [scripts/build_mini_app_for_railway.sh](scripts/build_mini_app_for_railway.sh).

FastAPI отдаёт Mini App с `/`, если есть `static_mini_app/index.html` (см. `backend/app/main.py`).

## 3. CORS и Telegram

- В **Variables** добавьте в `CORS_ORIGINS` origin вашего приложения на Railway, например  
  `https://gnatgminiapp-production.up.railway.app`  
  (и при необходимости Vercel, GitHub Pages, админку).

- В **BotFather** укажите **Web App URL** на тот же публичный URL Railway (например `https://gnatgminiapp-production.up.railway.app/`).

Подробнее по переменным: [backend/RAILWAY_VARIABLES_SETUP.md](backend/RAILWAY_VARIABLES_SETUP.md).
