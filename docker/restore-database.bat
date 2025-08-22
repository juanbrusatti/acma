@echo off
title Restaurar Base de Datos ACMA
cls

echo.
echo ===============================================
echo       RESTAURAR BASE DE DATOS ACMA
echo ===============================================
echo.

:: Verificar que estamos en el directorio correcto
if not exist "docker-compose.yml" (
    echo [ERROR] No se encontro docker-compose.yml
    echo         Ejecute este script desde el directorio 'docker'
    echo.
    pause
    exit /b 1
)

:: Verificar que existe la carpeta de backups
if not exist "backups" (
    echo [ERROR] No se encontro la carpeta de backups
    echo         No hay backups disponibles para restaurar
    echo.
    pause
    exit /b 1
)

echo Backups disponibles:
echo.
dir /b "backups\backup_acma_*" 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] No se encontraron backups
    echo.
    pause
    exit /b 1
)

echo.
echo TIPOS DE RESTAURACION:
echo.
echo 1) Restaurar desde SQL dump (recomendado)
echo 2) Restaurar archivos completos de PostgreSQL
echo 3) Listar detalles de backups disponibles
echo.
set /p tipo="Seleccione el tipo de restauracion (1-3): "

if "%tipo%"=="1" goto restaurar_sql
if "%tipo%"=="2" goto restaurar_archivos
if "%tipo%"=="3" goto listar_backups
goto tipo_invalido

:listar_backups
echo.
echo ===============================================
echo         DETALLES DE BACKUPS DISPONIBLES
echo ===============================================
echo.
for %%f in (backups\backup_acma_*) do (
    echo Backup: %%~nf
    echo   Fecha de creacion: %%~tf
    echo   Tamaño: %%~zf bytes
    if exist "%%f.sql" echo   Tipo: SQL dump
    if exist "%%f_data" echo   Tipo: Archivos completos
    if exist "%%f.zip" echo   Tipo: Comprimido ZIP
    if exist "%%f.7z" echo   Tipo: Comprimido 7Z
    echo.
)
pause
goto fin

:restaurar_sql
echo.
echo RESTAURACION DESDE SQL DUMP
echo.
echo ⚠️  ATENCION: Esto sobreescribira todos los datos actuales
echo.
set /p confirmar="¿Esta seguro? (s/N): "
if /i not "%confirmar%"=="s" goto fin

echo.
echo Archivos SQL disponibles:
dir /b "backups\*.sql" 2>nul
echo.
set /p archivo="Ingrese el nombre del archivo SQL (sin extension): "

if not exist "backups\%archivo%.sql" (
    echo [ERROR] Archivo no encontrado: backups\%archivo%.sql
    pause
    goto fin
)

echo.
echo [INFO] Restaurando desde: %archivo%.sql
echo.

:: Verificar que la base de datos esté corriendo
docker compose ps | findstr "db" | findstr "Up" >nul
if %errorlevel% neq 0 (
    echo [INFO] Iniciando base de datos...
    docker compose up -d db
    timeout /t 10
)

:: Borrar datos actuales y restaurar
echo [INFO] Borrando datos actuales...
docker compose exec db psql -U postgres -d acma_production -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;"

echo [INFO] Restaurando backup...
docker compose exec -T db psql -U postgres -d acma_production < "backups\%archivo%.sql"

if %errorlevel% equ 0 (
    echo [OK] Restauracion completada exitosamente
) else (
    echo [ERROR] Fallo en la restauracion
)
goto fin

:restaurar_archivos
echo.
echo RESTAURACION DE ARCHIVOS COMPLETOS
echo.
echo ⚠️  ATENCION: Esto reemplazara completamente la base de datos
echo ⚠️  Se perderan TODOS los datos actuales
echo.
set /p confirmar="¿Esta COMPLETAMENTE seguro? (s/N): "
if /i not "%confirmar%"=="s" goto fin

echo.
echo Carpetas de datos disponibles:
dir /b "backups\*_data" 2>nul
echo.
set /p carpeta="Ingrese el nombre de la carpeta (sin _data): "

if not exist "backups\%carpeta%_data" (
    echo [ERROR] Carpeta no encontrada: backups\%carpeta%_data
    pause
    goto fin
)

echo.
echo [INFO] Parando servicios...
docker compose down

echo [INFO] Respaldando datos actuales...
if exist "postgres_data_old" rmdir /s /q "postgres_data_old"
if exist "postgres_data" move "postgres_data" "postgres_data_old"

echo [INFO] Restaurando archivos...
xcopy /s /e /h /q "backups\%carpeta%_data" "postgres_data\" >nul

echo [INFO] Iniciando servicios...
docker compose up -d

echo [OK] Restauracion de archivos completada
echo [INFO] Los datos anteriores estan en: postgres_data_old
goto fin

:tipo_invalido
echo [ERROR] Tipo de restauracion invalido
goto fin

:fin
echo.
echo Presione cualquier tecla para salir...
pause >nul
