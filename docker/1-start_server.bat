@echo off
echo 🚀 Iniciando servidor Rails con Docker (DETACHED)...
echo.

:: Obtener la ruta del script
set "scriptDir=%~dp0"
cd /d "%scriptDir%"

echo 🔍 Verificando Docker...
set /a counter=0
set /a maxAttempts=100

:checkDocker
set /a counter+=1
echo 🔄 Intento %counter%/%maxAttempts% - Verificando Docker...

docker info >nul 2>&1
if not errorlevel 1 (
    echo ✅ Docker está funcionando!
    goto dockerReady
)

if %counter% geq %maxAttempts% (
    echo ❌ TIMEOUT: Docker no arrancó después de 100 intentos
    echo 📞 Por favor, revisa el estado de Docker Desktop.
    exit /b 1
)

echo ⏳ Docker aún no está listo... esperando 5 segundos
timeout /t 5 >nul
goto checkDocker

:dockerReady
echo 🐳 Docker está listo!

:: Verificar que existe docker-compose.yml
if not exist "docker-compose.yml" (
    echo ❌ ERROR: Archivo docker-compose.yml no encontrado
    echo 📍 Asegúrate de estar en la carpeta correcta.
    exit /b 1
)
echo ✅ Archivo docker-compose.yml encontrado

:: Levantar los contenedores en segundo plano
echo 🚢 Iniciando contenedores Docker en modo "detached"...
docker compose up -d

echo ✅ Servidor iniciado en segundo plano!
exit /b 0
