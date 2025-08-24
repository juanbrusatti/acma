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

echo ⚠️ Esto va a reemplazar la base de datos %DB% con el backup seleccionado.
pause

type "%BACKUP_DIR%\%FILE%" | docker exec -i %CONTAINER% psql -U %USER% -d %DB%

echo ✅ Restauración completada!
pause
