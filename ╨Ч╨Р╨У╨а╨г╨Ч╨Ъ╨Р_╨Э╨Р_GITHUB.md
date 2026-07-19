# Первая загрузка проекта на GitHub

1. Создайте пустой репозиторий без README и лицензии.
2. Распакуйте проект.
3. Запустите `ЗАГРУЗИТЬ_НА_GITHUB.bat`.
4. Вставьте HTTPS-адрес репозитория, например `https://github.com/USER/BoomBoom.git`.
5. После отправки откройте вкладку **Actions**.
6. Скачайте APK из артефакта `BoomArena-Android-APK`.

Ручные команды:

```bash
git init
git add .
git commit -m "Initial Boom Arena 0.8.2 project"
git branch -M main
git remote add origin https://github.com/USER/BoomBoom.git
git push -u origin main
```
