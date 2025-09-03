@echo off
:: ==============================================
:: start_server.bat - Solo PRODUCCIÓN (Optimizado para reinicio)
:: ==============================================

cd /d %~dp0

:: -----------------------------
:: 1️⃣ Variables de producción
:: -----------------------------
set RAILS_ENV=production
set DATABASE_URL=postgresql://postgres:Acma2024!Secure@host.docker.internal:5432/acma_production
set RAILS_PORT=3000
set PROD_RAILS_HOST=192.168.0.6

echo 🔹 Entorno fijo: %RAILS_ENV%
echo 🔹 DATABASE_URL: %DATABASE_URL%
echo 🔹 RAILS_PORT: %RAILS_PORT%


:: -----------------------------
:: 2️⃣ Iniciar Docker Desktop si no está corriendo
:: -----------------------------
tasklist /FI "IMAGENAME eq Docker Desktop.exe" | find /I "Docker Desktop.exe" >nul
if errorlevel 1 (
    echo 🐳 Abriendo Docker Desktop (minimizado)...
    start /MIN "" "C:\Program Files\Docker\Docker\Docker Desktop.exe"
) else (
    echo ✅ Docker Desktop ya estaba abierto
)

:: -----------------------------
:: 3️⃣ Esperar Docker (hasta 3 minutos)
:: -----------------------------
set /a counter=0
set /a maxAttempts=36
:checkDocker
set /a counter+=1
docker info >nul 2>&1
if not errorlevel 1 goto dockerReady
if %counter% geq %maxAttempts% (
    echo ❌ TIMEOUT: Docker no arrancó después de 3 minutos
    pause
    exit /b 1
)
timeout /t 5 >nul
goto checkDocker

:dockerReady
echo ✅ Docker listo

:: -----------------------------
:: 4️⃣ Verificar docker-compose.yml
:: -----------------------------
if not exist "docker-compose.yml" (
    echo ❌ ERROR: docker-compose.yml no encontrado
    pause
    exit /b 1
)
echo ✅ docker-compose.yml encontrado

:: -----------------------------
:: 5️⃣ Levantar contenedor web y loguear
:: -----------------------------
echo 🚀 Levantando contenedor web (Rails)...
docker compose up -d web >> "%~dp0start_server.log" 2>&1

:: -----------------------------
:: 6️⃣ Ejecutar migraciones en Rails y loguear
:: -----------------------------
echo 🛠️ Ejecutando migraciones en Rails...
docker exec -e RAILS_ENV=production web bundle exec rails db:prepare >> "%~dp0start_server.log" 2>&1
if errorlevel 1 (
    echo ❌ ERROR al ejecutar migraciones, revisar start_server.log
    pause
    exit /b 1
)
echo ✅ Migraciones completadas

:: -----------------------------
:: 7️⃣ Servidor iniciado
:: -----------------------------
echo ✅ Servidor Rails levantado en PRODUCCIÓN!
echo 🌐 Acceso: http://%PROD_RAILS_HOST%:%RAILS_PORT%
echo 📋 Para ver logs: docker compose logs -f
echo 🛑 Para detener servidor: Ctrl+C o cerrar esta ventana
