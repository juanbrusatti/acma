@echo off
:: ==============================================
:: run_migrations.bat - Ejecutar migraciones Rails
:: ==============================================

cd /d %~dp0

echo ================================
echo   Ejecutando Migraciones
echo ================================

:: -----------------------------
:: 1) Verificar Docker Desktop
:: -----------------------------
docker --version >nul 2>&1
if errorlevel 1 (
    echo ❌ ERROR: Docker Desktop no está instalado o no está en el PATH
    pause
    exit /b 1
)
echo Docker Desktop encontrado

:: -----------------------------
:: 2) Esperar que Docker arranque
:: -----------------------------
set /a counter=0
set /a maxAttempts=24
:checkDocker
set /a counter+=1
docker info >nul 2>&1
if not errorlevel 1 goto dockerReady
if %counter% geq %maxAttempts% (
    echo TIMEOUT: Docker no arrancó después de 2 minutos
    pause
    exit /b 1
)
timeout /t 5 >nul
goto checkDocker

:dockerReady
echo Docker listo

:: -----------------------------
:: 3) Verificar contenedor "web"
:: -----------------------------
docker ps -a --format "{{.Names}}" | findstr /i "web" >nul
if errorlevel 1 (
    echo ❌ ERROR: No existe un contenedor llamado "web"
    echo Asegurate de haber hecho: docker compose up -d
    pause
    exit /b 1
)
echo ✅ Contenedor web encontrado

:: -----------------------------
:: 4) Ejecutar migraciones
:: -----------------------------
echo 🚀 Ejecutando migraciones en Rails...
docker exec -e RAILS_ENV=production web bundle exec rails db:prepare

if errorlevel 1 (
    echo ❌ ERROR al correr las migraciones
    pause
    exit /b 1
)

echo ====================================
echo ✅ Migraciones ejecutadas correctamente
echo ====================================
pause
