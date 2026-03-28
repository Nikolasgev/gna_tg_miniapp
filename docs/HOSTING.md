# Выбор хостинга фронтенда (Mini App)

## Рекомендация проекта

Оставить **GitHub Pages** для статики Mini App и **Railway** для API — уже настроено в CI ([frontend/.github/workflows/deploy-gh-pages.yml](../frontend/.github/workflows/deploy-gh-pages.yml)).

## Сравнение

| Критерий | GitHub Pages (текущий) | Vercel | Yandex Cloud |
|----------|------------------------|--------|--------------|
| HTTPS для Telegram | Да (`*.github.io`) | Да | Да, после настройки |
| Сложность | Низкая (Actions) | Средняя (часто нужны override в UI) | Высокая (Object Storage + CDN или VM) |
| CORS | Настраивается на **backend** (Railway), не на хостинге фронта | То же | То же |
| Свой домен | Можно привязать к Pages | Можно | Удобно в РФ |

Переезд в Yandex Cloud **не убирает** необходимость правильного `CORS_ORIGINS` на FastAPI. Имеет смысл, если нужны данные/домен в РФ или единый origin (например, nginx на VM: фронт + прокси на API).

Vercel — разумно только если зафиксированы команды сборки без ручных override в панели (см. [frontend/vercel.json](../frontend/vercel.json), [frontend/build_vercel.sh](../frontend/build_vercel.sh)).

## Текущие URL (пример)

- Mini App: `https://nikolasgev.github.io/gna-tg-miniapp-store-frontend/`
- API: значение из `API_BASE_URL` в workflow и в Railway — см. [RAILWAY_VARIABLES_SETUP.md](../backend/RAILWAY_VARIABLES_SETUP.md)

При смене домена фронта: пересобрать с новым `--base-href` и `--dart-define=API_BASE_URL=...`, обновить `CORS_ORIGINS` и Web App URL в @BotFather.
