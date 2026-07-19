@echo off
chcp 65001 >nul
setlocal
cd /d "%~dp0"

echo ============================================
echo   Boom Arena 0.9 - обновление GitHub
echo ============================================

git rev-parse --is-inside-work-tree >nul 2>&1
if errorlevel 1 (
  echo ОШИБКА: эта папка не является локальным Git-репозиторием.
  echo Скопируйте содержимое проекта в папку репозитория BoomBoom.
  pause
  exit /b 1
)

git add -A

git diff --cached --quiet
if not errorlevel 1 (
  echo Изменений для отправки не найдено.
  pause
  exit /b 0
)

git commit -m "Boom Arena 0.9 tactical update"
if errorlevel 1 (
  echo ОШИБКА: не удалось создать коммит.
  pause
  exit /b 1
)

git push
if errorlevel 1 (
  echo ОШИБКА: git push не выполнен. Проверьте вход в GitHub и remote.
  pause
  exit /b 1
)

echo.
echo Готово. Откройте GitHub Actions и дождитесь сборки APK.
pause
