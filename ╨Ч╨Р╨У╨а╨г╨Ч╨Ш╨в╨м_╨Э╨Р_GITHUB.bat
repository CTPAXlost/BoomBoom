@echo off
chcp 65001 >nul
setlocal

where git >nul 2>nul
if errorlevel 1 (
  echo Git не найден. Установите Git for Windows и запустите файл снова.
  pause
  exit /b 1
)

echo.
set /p REPO_URL=Вставьте HTTPS-ссылку пустого GitHub-репозитория:
if "%REPO_URL%"=="" (
  echo Ссылка не введена.
  pause
  exit /b 1
)

cd /d "%~dp0"
if not exist .git git init

git config user.name "Boom Arena Developer"
git config user.email "boom-arena@local.invalid"
git add .
git commit -m "Initial Boom Arena 0.7 prototype" 2>nul || echo Изменения уже зафиксированы.
git branch -M main
git remote remove origin 2>nul
git remote add origin "%REPO_URL%"
git push -u origin main

if errorlevel 1 (
  echo.
  echo Загрузка не выполнена. Проверьте ссылку и авторизацию GitHub.
  pause
  exit /b 1
)

echo.
echo Проект загружен. Откройте вкладку Actions в репозитории.
pause
