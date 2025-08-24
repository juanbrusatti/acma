@echo off
echo 🚀 Iniciando servidor Rails con Docker...

:: Ir a la carpeta donde está tu docker-compose.yml
cd /d %~dp0

:: Asegurarse de que Docker Desktop esté levantado
echo ⏳ Esperando a que Docker arranque...
:checkDocker
docker info >nul 2>&1
if errorlevel 1 (
    timeout /t 5 >nul
    goto checkDocker
)

:: Levantar los contenedores
docker compose up -d

echo ✅ Servidor levantado en http://localhost:3000
pause
