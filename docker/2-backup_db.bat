@echo off
setlocal enabledelayedexpansion

:: Configuración
set PG_PATH="C:\Program Files\PostgreSQL\17\bin\pg_dump.exe"
set USER=postgres
set DB=acma_production
set HOST=localhost
set PORT=5432
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

:: Crear backup (silencioso)
%PG_PATH% -U %USER% -h %HOST% -p %PORT% -d %DB% -F p > "%FILE%" 2>nul

