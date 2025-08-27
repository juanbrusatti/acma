@echo off
setlocal enabledelayedexpansion

:: Configuración
set CONTAINER=db
set USER=postgres
set DB=acma_production
set BACKUP_DIR=%~dp0backups
set LOG_DIR=%BACKUP_DIR%\logs

:: Crear carpeta de backups y logs si no existen
if not exist "%BACKUP_DIR%" mkdir "%BACKUP_DIR%"
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"

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
set LOGFILE=%LOG_DIR%\error_%timestamp%.txt

echo 💾 Creando backup en %FILE% ...

docker exec %CONTAINER% pg_dump -U %USER% %DB% > "%FILE%" 2> "%LOGFILE%"

if %ERRORLEVEL% equ 0 (
    echo ✅ Backup completado!
    if exist "%LOGFILE%" del "%LOGFILE%"
) else (
    echo ❌ Error en el backup, revisa %LOGFILE%
)
