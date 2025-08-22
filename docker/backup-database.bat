@echo off
title Backup de Base de Datos ACMA - PostgreSQL
cls

echo.
echo ===============================================
echo         BACKUP DE BASE DE DATOS ACMA
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

:: Verificar que Docker está corriendo
docker info >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] Docker no esta corriendo.
    echo         Inicie Docker Desktop e intente nuevamente.
    echo.
    pause
    exit /b 1
)

:: Crear nombre de backup con fecha y hora
for /f "tokens=2 delims==" %%a in ('wmic OS Get localdatetime /value') do set "dt=%%a"
set "YY=%dt:~2,2%" & set "YYYY=%dt:~0,4%" & set "MM=%dt:~4,2%" & set "DD=%dt:~6,2%"
set "HH=%dt:~8,2%" & set "MIN=%dt:~10,2%" & set "SS=%dt:~12,2%"
set "TIMESTAMP=%YYYY%%MM%%DD%_%HH%%MIN%%SS%"
set "BACKUP_NAME=backup_acma_%TIMESTAMP%"

:: Crear carpeta de backups si no existe
if not exist "backups" (
    echo Creando carpeta de backups...
    mkdir backups
)

echo Creando backup: %BACKUP_NAME%
echo Timestamp: %TIMESTAMP%
echo.

:: Mostrar opciones de backup
echo Tipos de backup disponibles:
echo.
echo 1) Backup completo (SQL dump + archivos de datos)
echo 2) Solo SQL dump (mas rapido, solo datos)
echo 3) Solo copia de archivos (incluye configuraciones)
echo 4) Backup automatico (recomendado)
echo.
set /p tipo="Seleccione el tipo de backup (1-4): "

if "%tipo%"=="1" goto backup_completo
if "%tipo%"=="2" goto backup_sql
if "%tipo%"=="3" goto backup_archivos
if "%tipo%"=="4" goto backup_automatico
goto tipo_invalido

:backup_completo
echo.
echo [INFO] Realizando backup completo...
echo.

:: 1. SQL Dump
echo Paso 1/3: Creando SQL dump...
docker compose exec -T db pg_dump -U postgres -h localhost acma_production > "backups\%BACKUP_NAME%.sql"
if %errorlevel% neq 0 (
    echo [ERROR] Fallo al crear SQL dump
    goto error_exit
)
echo [OK] SQL dump creado: %BACKUP_NAME%.sql

:: 2. Copia de archivos de datos
echo Paso 2/3: Copiando archivos de PostgreSQL...
if exist "backups\%BACKUP_NAME%_data" rmdir /s /q "backups\%BACKUP_NAME%_data"
xcopy /s /e /h /q "postgres_data" "backups\%BACKUP_NAME%_data\" >nul
if %errorlevel% neq 0 (
    echo [ERROR] Fallo al copiar archivos de datos
    goto error_exit
)
echo [OK] Archivos de datos copiados

:: 3. Copia de configuraciones
echo Paso 3/3: Copiando configuraciones...
copy ".env" "backups\%BACKUP_NAME%_config.env" >nul
copy "docker-compose.yml" "backups\%BACKUP_NAME%_docker-compose.yml" >nul
echo [OK] Configuraciones copiadas

goto backup_exitoso

:backup_sql
echo.
echo [INFO] Realizando backup SQL...
echo.
docker compose exec -T db pg_dump -U postgres -h localhost acma_production > "backups\%BACKUP_NAME%.sql"
if %errorlevel% neq 0 (
    echo [ERROR] Fallo al crear SQL dump
    goto error_exit
)
echo [OK] SQL dump creado: %BACKUP_NAME%.sql
goto backup_exitoso

:backup_archivos
echo.
echo [INFO] Copiando archivos de datos...
echo.
if exist "backups\%BACKUP_NAME%_data" rmdir /s /q "backups\%BACKUP_NAME%_data"
xcopy /s /e /h /q "postgres_data" "backups\%BACKUP_NAME%_data\" >nul
if %errorlevel% neq 0 (
    echo [ERROR] Fallo al copiar archivos
    goto error_exit
)
echo [OK] Archivos copiados a: %BACKUP_NAME%_data\
goto backup_exitoso

:backup_automatico
echo.
echo [INFO] Realizando backup automatico (SQL + configuraciones)...
echo.

:: SQL Dump con compresion
echo Creando SQL dump comprimido...
docker compose exec -T db pg_dump -U postgres -h localhost acma_production | powershell -command "& {$input | Out-File -Encoding UTF8 'backups\%BACKUP_NAME%.sql'}"
if %errorlevel% neq 0 (
    echo [ERROR] Fallo al crear SQL dump
    goto error_exit
)

:: Comprimir con 7zip si esta disponible, sino usar powershell
where 7z >nul 2>nul
if %errorlevel% equ 0 (
    echo Comprimiendo con 7-Zip...
    7z a "backups\%BACKUP_NAME%.7z" "backups\%BACKUP_NAME%.sql" ".env" "docker-compose.yml" >nul
    del "backups\%BACKUP_NAME%.sql"
    echo [OK] Backup comprimido creado: %BACKUP_NAME%.7z
) else (
    echo Comprimiendo con PowerShell...
    powershell -command "Compress-Archive -Path 'backups\%BACKUP_NAME%.sql','.env','docker-compose.yml' -DestinationPath 'backups\%BACKUP_NAME%.zip'"
    del "backups\%BACKUP_NAME%.sql"
    echo [OK] Backup comprimido creado: %BACKUP_NAME%.zip
)
goto backup_exitoso

:tipo_invalido
echo [ERROR] Tipo de backup invalido
goto error_exit

:backup_exitoso
echo.
echo ===============================================
echo           BACKUP COMPLETADO EXITOSAMENTE
echo ===============================================
echo.
echo Detalles del backup:
echo - Nombre: %BACKUP_NAME%
echo - Fecha: %DD%/%MM%/%YYYY% %HH%:%MIN%:%SS%
echo - Ubicacion: %CD%\backups\
echo.

:: Mostrar tamaño de los archivos creados
echo Archivos creados:
dir /b "backups\%BACKUP_NAME%*" 2>nul
echo.

:: Mostrar información de la base de datos
echo Informacion de la base de datos:
docker compose exec db psql -U postgres -d acma_production -c "SELECT pg_size_pretty(pg_database_size('acma_production')) as database_size;"
echo.

echo ===============================================
echo.
echo INSTRUCCIONES DE RESTAURACION:
echo.
echo Para SQL dump:
echo   docker compose exec -T db psql -U postgres -d acma_production ^< backups\%BACKUP_NAME%.sql
echo.
echo Para archivos completos:
echo   1. docker compose down
echo   2. rmdir /s postgres_data
echo   3. xcopy backups\%BACKUP_NAME%_data postgres_data\ /s /e /h
echo   4. docker compose up -d
echo.
goto fin

:error_exit
echo.
echo [ERROR] El backup fallo. Verifique:
echo - Que Docker este corriendo
echo - Que la base de datos este accesible
echo - Que tenga permisos de escritura
echo.

:fin
echo Presione cualquier tecla para salir...
pause >nul
