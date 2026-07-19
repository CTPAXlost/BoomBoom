@echo off
chcp 65001 >nul
setlocal
cd /d "%~dp0"

echo ============================================
echo   Boom Arena 0.9 - первая загрузка GitHub
echo ============================================
echo.
set /p REPO_URL=Вставьте HTTPS-ссылку пустого репозитория: 
if "%REPO_URL%"=="" (
  echo ОШИБКА: ссылка не введена.
  pause
  exit /b 1
)

if not exist .git (
  git init
)
git branch -M main
git remote remove origin >nul 2>&1
git remote add origin "%REPO_URL%"
git add -A
git commit -m "Boom Arena 0.9 initial project"
if errorlevel 1 (
  echo Коммит не создан. Возможно, файлы уже закоммичены.
)
git push -u origin main
if errorlevel 1 (
  echo ОШИБКА: отправка не выполнена. Проверьте адрес и авторизацию GitHub.
  pause
  exit /b 1
)

echo.
echo Готово. Откройте вкладку Actions в репозитории.
pause
