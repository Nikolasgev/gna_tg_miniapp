# Исправление Vercel — 1 минута

Код с `build_vercel.sh` и `vercel.json` уже запушен в GitHub.

**Причина ошибки:** в настройках проекта Vercel заданы свои команды (Install: `echo 'No install needed'`), они переопределяют `vercel.json`.

## Что сделать (один раз)

1. Открой https://vercel.com/dashboard
2. Выбери проект **gna-tg-miniapp-store-frontend**
3. Вкладка **Settings** → слева **Build & Development Settings**
4. Сними все галочки **Override** у полей:
   - **Build Command**
   - **Install Command** 
   - **Output Directory**
5. Сохрани и нажми **Redeploy** на вкладке Deployments

После этого Vercel будет использовать `vercel.json` из репозитория.
