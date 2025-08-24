@echo off
setlocal enabledelayedexpansion

:: Configuración
set CONTAINER=db
set USER=postgres
set DB=acma_production
set BACKUP_DIR=%~dp0backups

:: Crear carpeta de backups si no existe
if not exist "%BACKUP_DIR%" mkdir "%BACKUP_DIR%"

:: Fecha y hora para el nombre del archivo
for /f "tokens=1-4 delims=/ " %%i in ("%date%") do (
    set day=%%i
    set month=%%j
    set year=%%k
)
set timestamp=%year%-%month%-%day%_%time:~0,2%-%time:~3,2%
set timestamp=%timestamp: =0%

:: Archivo final
set FILE=%BACKUP_DIR%\backup_%timestamp%.sql

echo 💾 Creando backup en %FILE% ...

docker exec %CONTAINER% pg_dump -U %USER% %DB% > "%FILE%"

echo ✅ Backup completado!
pause
