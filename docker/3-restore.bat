@echo off
setlocal enabledelayedexpansion

:: Configuración
set PSQL_PATH="C:\Program Files\PostgreSQL\17\bin\psql.exe"
set USER=postgres
set DB=acma_production
set HOST=localhost
set PORT=5432
set BACKUP_DIR=%~dp0backups

echo 📂 Buscando backups disponibles en %BACKUP_DIR%
dir /b "%BACKUP_DIR%\*.sql"

set /p FILE="👉 Escribe el nombre del backup a restaurar: "

if not exist "%BACKUP_DIR%\%FILE%" (
    echo ❌ El archivo %FILE% no existe.
    pause
    exit /b
)

echo ⚠️ Esto va a borrar y recrear la base de datos %DB% antes de restaurar.
pause

:: Borrar conexiones activas y eliminar la base de datos
%PSQL_PATH% -U %USER% -h %HOST% -p %PORT% -d postgres -c "REVOKE CONNECT ON DATABASE %DB% FROM public;"
%PSQL_PATH% -U %USER% -h %HOST% -p %PORT% -d postgres -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname='%DB%' AND pid <> pg_backend_pid();"
%PSQL_PATH% -U %USER% -h %HOST% -p %PORT% -d postgres -c "DROP DATABASE IF EXISTS %DB%;"
%PSQL_PATH% -U %USER% -h %HOST% -p %PORT% -d postgres -c "CREATE DATABASE %DB% WITH OWNER=%USER%;"

:: Restaurar el backup
%PSQL_PATH% -U %USER% -h %HOST% -p %PORT% -d %DB% -f "%BACKUP_DIR%\%FILE%"

echo ✅ Restauración completada!

:: Ejecutar migraciones desde el contenedor Rails
echo 🚀 Ejecutando migraciones en Rails...
docker compose exec web bundle exec rails db:migrate RAILS_ENV=production

echo ✅ Migraciones aplicadas correctamente!
pause
