@echo off
setlocal enabledelayedexpansion

echo ===============================================
echo   🚀 Iniciando proceso de backup de PostgreSQL
echo ===============================================

:: Configuración
set PG_PATH="C:\Program Files\PostgreSQL\17\bin\pg_dump.exe"
set USER=postgres
set DB=acma_production
set HOST=localhost
set PORT=5432
set BACKUP_DIR=%~dp0backups

echo [INFO] Configuración:
echo   PG_PATH: %PG_PATH%
echo   Usuario: %USER%
echo   Base de datos: %DB%
echo   Host: %HOST%
echo   Puerto: %PORT%
echo   Carpeta de backups: %BACKUP_DIR%
echo.

:: Crear carpeta de backups si no existe
if not exist "%BACKUP_DIR%" (
    echo [INFO] Carpeta de backups no existe. Creando...
    mkdir "%BACKUP_DIR%"
) else (
    echo [INFO] Carpeta de backups ya existe.
)

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
echo [INFO] Nombre del archivo de backup: %FILE%
echo.

:: Crear backup
echo [INFO] Ejecutando pg_dump...
%PG_PATH% -U %USER% -h %HOST% -p %PORT% -d %DB% -F p > "%FILE%" 2>error.log

if %ERRORLEVEL%==0 (
    echo [OK] Backup generado con éxito en: %FILE%
) else (
    echo [ERROR] Ocurrió un error durante el backup.
    echo Revisá el archivo error.log para más detalles.
)

echo ===============================================
echo   ✅ Proceso finalizado
echo ===============================================
