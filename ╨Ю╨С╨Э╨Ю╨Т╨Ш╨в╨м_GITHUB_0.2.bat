@echo off
chcp 65001 >nul
setlocal
cd /d "%~dp0"

echo ========================================
echo  Boom Arena 0.2 - обновление GitHub
echo ========================================
echo.

where git >nul 2>nul
if errorlevel 1 (
  echo ОШИБКА: Git не установлен.
  pause
  exit /b 1
)

if not exist .git (
  git init
  git branch -M main
  set /p REPO=Вставь HTTPS-ссылку репозитория GitHub: 
  git remote add origin "%REPO%"
) else (
  git remote -v
)

git add -A
git commit -m "Fix Godot 4.7 Android build and GDScript errors"
git push -u origin main

if errorlevel 1 (
  echo.
  echo Загрузка не завершена. Проверь адрес репозитория и авторизацию GitHub.
) else (
  echo.
  echo Готово. Открой GitHub - Actions - Build Android APK.
)
pause
