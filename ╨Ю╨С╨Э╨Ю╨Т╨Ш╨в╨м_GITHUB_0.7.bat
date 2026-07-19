@echo off
chcp 65001 >nul
setlocal
cd /d "%~dp0"

where git >nul 2>nul
if errorlevel 1 goto nogit

if not exist .git (
  echo Эта папка не является локальным Git-репозиторием.
  echo Скопируйте содержимое версии 0.7 в папку вашего репозитория.
  pause
  exit /b 1
)

if not exist .github\workflows\android.yml goto missing
if not exist signing\boomarena-debug.keystore goto missing

echo Обновление Boom Arena до 0.7...
python scripts\validate_project.py
if errorlevel 1 goto error

git add -A
if errorlevel 1 goto error

git commit -m "Boom Arena 0.7 progression sniper aim consumables graphics"
if errorlevel 1 echo Новых изменений для коммита нет или commit уже создан.

git push origin main
if errorlevel 1 goto error

echo.
echo Готово. Откройте GitHub Actions и дождитесь зелёной сборки.
pause
exit /b 0

:missing
echo Не найдены .github\workflows\android.yml или signing\boomarena-debug.keystore.
echo Скопируйте проект целиком, включая скрытые папки.
pause
exit /b 1

:nogit
echo Git не найден. Установите Git for Windows.
pause
exit /b 1

:error
echo.
echo Ошибка проверки или Git. Проверьте файлы, ветку main и авторизацию GitHub.
pause
exit /b 1
