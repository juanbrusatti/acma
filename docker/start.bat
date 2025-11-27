@echo off
:: ==============================================
:: build_and_start.bat - Producción
:: ==============================================

cd /d %~dp0

echo ====================================================
echo 🔍 Verificando Docker Desktop...
echo ====================================================
docker --version >nul 2>&1
if errorlevel 1 (
    echo ❌ ERROR: Docker Desktop no está instalado o no está en el PATH.
    pause
    exit /b 1
)
echo ✅ Docker encontrado

echo ====================================================
echo ⏳ Esperando que Docker arranque...
echo ====================================================
set /a counter=0
:checkDocker
set /a counter+=1
docker info >nul 2>&1
if not errorlevel 1 goto dockerReady
if %counter% geq 20 (
    echo ❌ ERROR: Docker no arrancó después de 1 minuto.
    pause
    exit /b 1
)
timeout /t 3 >nul
goto checkDocker

:dockerReady
echo ✅ Docker está listo

echo ====================================================
echo 🔍 Verificando docker-compose.yml...
echo ====================================================
if not exist "docker-compose.yml" (
    echo ❌ ERROR: docker-compose.yml NO se encuentra en esta carpeta.
    pause
    exit /b 1
)
echo ✅ docker-compose.yml encontrado

echo ====================================================
echo 🔨 Reconstruyendo imagen SIN CACHE...
echo ====================================================
docker compose --profile production build --no-cache
if errorlevel 1 (
    echo ❌ ERROR durante el build.
    pause
    exit /b 1
)

echo ====================================================
echo 🚀 Levantando contenedor web...
echo ====================================================
docker compose --profile production up -d
if errorlevel 1 (
    echo ❌ ERROR al levantar el contenedor web.
    pause
    exit /b 1
)

echo ====================================================
echo 🎉 LISTO! El sistema está funcionando.
echo ====================================================
docker ps

pause
