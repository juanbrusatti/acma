@echo off
echo 🚀 Iniciando servidor Rails con Docker...

:: Ir a la carpeta donde está tu docker-compose.yml
cd /d %~dp0

:: Verificar que Docker Desktop esté instalado
echo 🔍 Verificando Docker Desktop...
docker --version >nul 2>&1
if errorlevel 1 (
    echo ❌ ERROR: Docker Desktop no está instalado o no está en el PATH
    echo 📥 Por favor instala Docker Desktop desde: https://www.docker.com/products/docker-desktop
    pause
    exit /b 1
)

echo ✅ Docker Desktop encontrado
echo ⏳ Esperando a que Docker arranque completamente...

:: Contador para timeout (máximo 2 minutos = 24 intentos de 5 segundos)
set /a counter=0
set /a maxAttempts=24

:checkDocker
set /a counter+=1
echo 🔄 Intento %counter%/%maxAttempts% - Verificando Docker...

docker info >nul 2>&1
if not errorlevel 1 (
    echo ✅ Docker está funcionando!
    goto dockerReady
)

if %counter% geq %maxAttempts% (
    echo ❌ TIMEOUT: Docker no arrancó después de 2 minutos
    echo 🔧 Soluciones posibles:
    echo    1. Abre Docker Desktop manualmente y espera que arranque
    echo    2. Reinicia Docker Desktop
    echo    3. Reinicia tu PC
    echo 📞 Si el problema persiste, contacta soporte técnico
    pause
    exit /b 1
)

echo ⏳ Docker aún no está listo... esperando 5 segundos
timeout /t 5 >nul
goto checkDocker

:dockerReady
echo 🐳 Docker está listo! Iniciando aplicación...

:dockerReady
echo 🐳 Docker está listo! Iniciando aplicación...

:: Verificar que existe el archivo .env
if not exist ".env" (
    echo ❌ ERROR: Archivo .env no encontrado
    echo 📄 Necesitas copiar el archivo .env en esta carpeta
    echo 📍 Ruta esperada: %~dp0.env
    pause
    exit /b 1
)
echo ✅ Archivo .env encontrado

:: Verificar que existe docker-compose.yml
if not exist "docker-compose.yml" (
    echo ❌ ERROR: Archivo docker-compose.yml no encontrado
    echo 📍 Asegúrate de estar en la carpeta correcta: C:\acma\docker\
    pause
    exit /b 1
)
echo ✅ Archivo docker-compose.yml encontrado

:: Levantar los contenedores
echo 🚢 Iniciando contenedores Docker...
docker compose up -d

if errorlevel 1 (
    echo ❌ ERROR: Falló al iniciar los contenedores
    echo 📋 Comandos de diagnóstico:
    echo    docker compose logs
    echo    docker compose down
    echo    docker system prune
    pause
    exit /b 1
)

echo ✅ Servidor levantado exitosamente!
echo 🌐 Accede a la aplicación en: http://localhost:3000
echo 📋 Comandos útiles:
echo    Para ver logs: docker compose logs
echo    Para parar: docker compose down
echo.
pause
