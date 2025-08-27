@echo off
setlocal enabledelayedexpansion

:: Configuración
set CONTAINER=docker-db-1
set USER=postgres
set DB=acma_production
set BACKUP_DIR=%~dp0backups
set LOG_DIR=%BACKUP_DIR%\logs

:: Crear carpetas si no existen
if not exist "%BACKUP_DIR%" mkdir "%BACKUP_DIR%"
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"

:: Fecha y hora para el nombre del archivo (formato mejorado)
for /f "tokens=2-4 delims=/ " %%a in ('date /t') do (
    set month=%%a
    set day=%%b
    set year=%%c
)
for /f "tokens=1-2 delims=: " %%a in ('time /t') do (
    set hour=%%a
    set minute=%%b
)

:: Limpiar formato de hora
set hour=%hour: =0%
set minute=%minute: =0%
if "%hour:~0,1%"==" " set hour=0%hour:~1,1%

set timestamp=%year%-%month%-%day%_%hour%-%minute%
set FILE=%BACKUP_DIR%\acma_backup_%timestamp%.sql
set LOG_FILE=%LOG_DIR%\backup_log_%timestamp%.txt

:: Si se ejecuta desde Administrador de Tareas (sin ventana), solo hacer backup
if "%1"=="--auto" goto auto_mode

:: Modo manual (con mensajes para usuario)
echo 💾 Creando backup en %FILE% ...

:: Verificar que Docker esté corriendo
docker ps >nul 2>&1
if errorlevel 1 (
    echo ❌ ERROR: Docker no está corriendo
    echo ℹ️  Asegúrate de que Docker Desktop esté iniciado
    pause
    exit /b 1
)

:: Verificar que el contenedor esté corriendo
docker ps | findstr "%CONTAINER%" >nul 2>&1
if errorlevel 1 (
    echo ❌ ERROR: El contenedor de base de datos no está corriendo
    echo ℹ️  Ejecuta primero: 1-start_server.bat
    pause
    exit /b 1
)

:: Crear backup
docker exec %CONTAINER% pg_dump -U %USER% %DB% > "%FILE%"

:: Verificar resultado
if exist "%FILE%" (
    for %%A in ("%FILE%") do (
        if %%~zA GTR 0 (
            echo ✅ Backup creado exitosamente: %%~zA bytes
            echo 📁 Ubicación: %FILE%
        ) else (
            echo ❌ ERROR: Backup creado pero está vacío
            del "%FILE%"
        )
    )
) else (
    echo ❌ ERROR: No se pudo crear el backup
)

pause
exit /b 0

:: Modo automático (sin interacción, para Administrador de Tareas)
:auto_mode
echo [%date% %time%] INICIO DE BACKUP AUTOMATICO > "%LOG_FILE%"
echo [%date% %time%] Archivo destino: %FILE% >> "%LOG_FILE%"

:: Verificar que Docker esté corriendo
docker ps >nul 2>&1
if errorlevel 1 (
    echo [%date% %time%] ERROR: Docker no está corriendo >> "%LOG_FILE%"
    exit /b 1
)

:: Verificar que el contenedor esté corriendo
docker ps | findstr "%CONTAINER%" >nul 2>&1
if errorlevel 1 (
    echo [%date% %time%] ERROR: Contenedor %CONTAINER% no está corriendo >> "%LOG_FILE%"
    exit /b 1
)

:: Crear backup
echo [%date% %time%] Iniciando backup... >> "%LOG_FILE%"
docker exec %CONTAINER% pg_dump -U %USER% %DB% > "%FILE%" 2>>"%LOG_FILE%"

:: Verificar resultado
if exist "%FILE%" (
    for %%A in ("%FILE%") do (
        if %%~zA GTR 0 (
            echo [%date% %time%] BACKUP EXITOSO: %%~zA bytes >> "%LOG_FILE%"
            echo [%date% %time%] Archivo: %FILE% >> "%LOG_FILE%"
        ) else (
            echo [%date% %time%] ERROR: Backup creado pero vacío >> "%LOG_FILE%"
            del "%FILE%"
            exit /b 1
        )
    )
) else (
    echo [%date% %time%] ERROR: No se pudo crear el archivo de backup >> "%LOG_FILE%"
    exit /b 1
)

:: Limpiar backups antiguos (mantener solo los últimos 30)
echo [%date% %time%] Limpiando backups antiguos... >> "%LOG_FILE%"
for /f "skip=30 delims=" %%i in ('dir /b /o-d "%BACKUP_DIR%\acma_backup_*.sql" 2^>nul') do (
    del "%BACKUP_DIR%\%%i" 2>>"%LOG_FILE%"
    echo [%date% %time%] Eliminado backup antiguo: %%i >> "%LOG_FILE%"
)

echo [%date% %time%] BACKUP COMPLETADO EXITOSAMENTE >> "%LOG_FILE%"
exit /b 0
