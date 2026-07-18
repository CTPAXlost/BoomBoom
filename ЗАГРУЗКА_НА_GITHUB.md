# Как загрузить проект на GitHub

Самый простой вариант на Windows: создайте пустой репозиторий, затем запустите `ЗАГРУЗИТЬ_НА_GITHUB.bat` и вставьте его HTTPS-ссылку. Скрипт загрузит весь проект вместе со скрытой папкой `.github`.


## Через сайт GitHub

1. На GitHub нажмите **New repository**.
2. Имя: `boom-arena`.
3. Не добавляйте README, `.gitignore` и лицензию — они уже есть.
4. Создайте репозиторий.
5. Распакуйте архив проекта.
6. На странице репозитория нажмите **uploading an existing file**.
7. Перетащите всё содержимое папки проекта, включая `.github`.
8. Нажмите **Commit changes**.
9. Откройте **Actions → Build Android APK → Run workflow**.
10. Скачайте готовый APK из блока **Artifacts**.

## Через Git на Windows

В PowerShell внутри папки проекта:

```powershell
git init
git add .
git commit -m "Initial Boom Arena prototype"
git branch -M main
git remote add origin https://github.com/ВАШ_ЛОГИН/boom-arena.git
git push -u origin main
```
