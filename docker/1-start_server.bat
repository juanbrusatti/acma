@echo off
echo 🚀 Iniciando servidor Rails con Docker (DETACHED)...

:: Ir a la carpeta donde está docker-compose.yml
cd /d %~dp0

:: Verificar que Docker está disponible
docker info >nul 2>&1
if errorlevel 1 (
    echo ❌ ERROR: Docker no está disponible
    exit /b 1
)

:: Levantar los contenedores en segundo plano
docker compose up -d

echo ✅ Servidor iniciado en segundo plano!
exit /b 0
