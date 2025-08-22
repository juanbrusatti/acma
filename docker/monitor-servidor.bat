@echo off
title Monitor de Servidor ACMA - Tiempo Real
cls

echo.
echo ===============================================
echo        MONITOR SERVIDOR ACMA - TIEMPO REAL
echo ===============================================
echo.
echo Presiona Ctrl+C para salir
echo.

:loop
cls
echo ===============================================
echo        MONITOR SERVIDOR ACMA - %date% %time%
echo ===============================================
echo.

:: Estado de servicios Docker
echo === ESTADO DE SERVICIOS ===
docker compose ps 2>nul || (
    echo [ERROR] Docker no disponible o servicios no iniciados
    echo [INFO] Ejecutar: start-server.bat
    goto :sleep
)

echo.

:: Uso de recursos
echo === USO DE RECURSOS ===
echo.

:: CPU y Memoria de contenedores
echo Contenedores Docker:
docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}" 2>nul || echo [INFO] No hay contenedores corriendo

echo.

:: Espacio en disco
echo Espacio en disco C:\:
for /f "tokens=3" %%a in ('dir C:\ /-c ^| find "bytes free"') do set FREE_SPACE=%%a
set /a FREE_GB=%FREE_SPACE:~0,-9%
echo Espacio libre: %FREE_GB% GB

if %FREE_GB% lss 5 (
    echo [ALERTA] Poco espacio en disco!
) else if %FREE_GB% lss 10 (
    echo [AVISO] Espacio limitado
) else (
    echo [OK] Espacio suficiente
)

echo.

:: Estado de red
echo === ESTADO DE RED ===
echo.

:: Verificar puerto 3000
netstat -an | findstr ":3000" | findstr "LISTENING" >nul
if %errorlevel% equ 0 (
    echo Puerto 3000: [ACTIVO] Servidor corriendo
) else (
    echo Puerto 3000: [INACTIVO] Servidor no disponible
)

:: IP actual
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /c:"IPv4"') do (
    set IP=%%a
    set IP=!IP: =!
    goto :ip_found
)
:ip_found
echo IP del servidor: %IP%

:: Test de conectividad
curl -s --max-time 3 http://localhost:3000 >nul 2>&1
if %errorlevel% equ 0 (
    echo Conectividad local: [OK] Accesible
) else (
    echo Conectividad local: [ERROR] No accesible
)

curl -s --max-time 3 http://%IP%:3000 >nul 2>&1
if %errorlevel% equ 0 (
    echo Conectividad red: [OK] Accesible desde %IP%
) else (
    echo Conectividad red: [ERROR] No accesible por IP
)

echo.

:: Logs recientes (últimas 5 líneas)
echo === LOGS RECIENTES ===
echo.
docker compose logs --tail=5 web 2>nul | findstr /v "^$" || echo [INFO] No hay logs disponibles

echo.

:: Backups
echo === BACKUPS ===
echo.
if exist "backups" (
    set BACKUP_COUNT=0
    for %%f in (backups\backup_acma_*) do set /a BACKUP_COUNT+=1
    echo Backups totales: %BACKUP_COUNT%

    if %BACKUP_COUNT% gtr 0 (
        for /f "delims=" %%a in ('dir /b /o-d backups\backup_acma_* 2^>nul') do (
            echo Ultimo backup: %%a
            goto :backup_found
        )
        :backup_found
    ) else (
        echo [AVISO] No hay backups creados
    )
) else (
    echo [INFO] Directorio de backups no existe
)

echo.

:: Información del sistema
echo === INFORMACION DEL SISTEMA ===
echo Usuario: %USERNAME%
echo Computadora: %COMPUTERNAME%
echo Directorio: %CD%
echo.

:sleep
echo Actualizando en 10 segundos... (Ctrl+C para salir)
timeout /t 10 /nobreak >nul
goto :loop
