@echo off
chcp 65001 >nul
setlocal

if not exist ".git" (
  echo В этой папке нет каталога .git.
  echo Скопируйте содержимое Boom Arena 0.8 в локальную папку вашего репозитория.
  pause
  exit /b 1
)

if not exist ".github\workflows\android.yml" (
  echo Не найдена скрытая папка .github\workflows.
  echo Включите показ скрытых файлов и скопируйте проект ещё раз.
  pause
  exit /b 1
)

echo Проверка проекта...
python scripts\validate_project.py
if errorlevel 1 (
  echo Проверка не пройдена.
  pause
  exit /b 1
)

echo Отправка Boom Arena 0.8...
git add -A
git commit -m "Boom Arena 0.8 saloon control shop audio scoring reload"
if errorlevel 1 echo Возможно, изменения уже зафиксированы.
git push
if errorlevel 1 (
  echo Не удалось выполнить git push.
  pause
  exit /b 1
)

echo Готово. Откройте GitHub Actions и дождитесь Build Android APK.
pause
