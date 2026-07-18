@echo off
chcp 65001 >nul
setlocal
cd /d "%~dp0"

echo Обновление Boom Arena 0.3...
git add -A
if errorlevel 1 goto error

git commit -m "Fix APK artifact path and verification"
if errorlevel 1 echo Изменений для коммита нет или commit уже создан.

git push origin main
if errorlevel 1 goto error

echo.
echo Готово. Откройте GitHub Actions и дождитесь зелёной сборки.
pause
exit /b 0

:error
echo.
echo Ошибка Git. Проверьте, что эта папка является локальным репозиторием и выполнен вход в GitHub.
pause
exit /b 1
