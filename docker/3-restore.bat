@echo off
setlocal enabledelayedexpansion

:: Configuración
set CONTAINER=db
set USER=postgres
set DB=acma_production
set BACKUP_DIR=%~dp0backups

echo 📂 Buscando backups disponibles en %BACKUP_DIR%
dir /b "%BACKUP_DIR%\*.sql"

set /p FILE="👉 Escribe el nombre del backup a restaurar: "

if not exist "%BACKUP_DIR%\%FILE%" (
    echo ❌ El archivo %FILE% no existe.
    pause
    exit /b
)

echo ✅ Restauración completada!
pause
echo ⚠️ Esto va a borrar y recrear la base de datos %DB% antes de restaurar.
pause

:: Borrar conexiones activas y eliminar la base de datos
docker exec -i %CONTAINER% psql -U %USER% -d postgres -c "REVOKE CONNECT ON DATABASE %DB% FROM public;"
docker exec -i %CONTAINER% psql -U %USER% -d postgres -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname='%DB%';"
docker exec -i %CONTAINER% psql -U %USER% -d postgres -c "DROP DATABASE IF EXISTS %DB%;"
docker exec -i %CONTAINER% psql -U %USER% -d postgres -c "CREATE DATABASE %DB% WITH OWNER=%USER%;"

:: Restaurar el backup
type "%BACKUP_DIR%\%FILE%" | docker exec -i %CONTAINER% psql -U %USER% -d %DB%

echo ✅ Restauración completada!
pause
