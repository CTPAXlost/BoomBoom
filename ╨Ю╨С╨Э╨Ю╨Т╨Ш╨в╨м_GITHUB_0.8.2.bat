@echo off
chcp 65001 >nul
setlocal
cd /d "%~dp0"

echo Проверка Git-репозитория...
if not exist ".git" (
  echo ОШИБКА: папка .git не найдена. Скопируйте содержимое проекта в локальную папку репозитория BoomBoom.
  pause
  exit /b 1
)

echo Добавление файлов Boom Arena 0.8.2...
git add -A

git diff --cached --quiet
if %errorlevel%==0 (
  echo Изменений для отправки нет.
  pause
  exit /b 0
)

git commit -m "Boom Arena 0.8.2: fix Godot import smoke test"
if errorlevel 1 goto :error

git push
if errorlevel 1 goto :error

echo.
echo Готово. Откройте GitHub Actions и дождитесь завершения сборки.
pause
exit /b 0

:error
echo.
echo Не удалось отправить обновление. Проверьте авторизацию Git и адрес репозитория.
pause
exit /b 1
