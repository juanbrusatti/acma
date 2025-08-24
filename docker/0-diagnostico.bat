@echo off
echo 🔧 DIAGNÓSTICO DE DOCKER - ACMA
echo ================================

echo.
echo 📊 Verificando Docker Desktop...
docker --version
if errorlevel 1 (
    echo ❌ Docker no está instalado o no está en el PATH
    goto end
)

echo.
echo 📊 Verificando estado de Docker...
docker info
if errorlevel 1 (
    echo ❌ Docker no está funcionando
    echo 💡 Solución: Abre Docker Desktop y espera que arranque
    goto end
)

echo.
echo 📊 Verificando contenedores...
docker ps -a

echo.
echo 📊 Verificando imágenes...
docker images

echo.
echo 📊 Verificando archivos necesarios...
if exist ".env" (
    echo ✅ Archivo .env: ENCONTRADO
) else (
    echo ❌ Archivo .env: NO ENCONTRADO
)

if exist "docker-compose.yml" (
    echo ✅ Archivo docker-compose.yml: ENCONTRADO
) else (
    echo ❌ Archivo docker-compose.yml: NO ENCONTRADO
)

echo.
echo 📊 Verificando puertos...
netstat -an | findstr ":3000"
if errorlevel 1 (
    echo ✅ Puerto 3000: LIBRE
) else (
    echo ⚠️ Puerto 3000: EN USO
)

echo.
echo 📊 Verificando logs de la aplicación...
docker compose logs --tail=10

:end
echo.
echo 🏁 Diagnóstico completado
pause
