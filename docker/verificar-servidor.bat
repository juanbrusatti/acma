@echo off
title Verificador del Servidor ACMA
cls

echo.
echo ===============================================
echo         VERIFICADOR SERVIDOR ACMA
echo ===============================================
echo.
echo Ejecutando diagnostico completo del sistema...
echo.

set ERROR_COUNT=0
set WARNING_COUNT=0

:: Verificar permisos de administrador
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [AVISO] Ejecutando sin permisos de administrador
    echo         Algunos checks pueden ser limitados
    set /a WARNING_COUNT+=1
) else (
    echo [OK] Permisos de administrador verificados
)
echo.

:: ========================================
:: VERIFICACIONES DE SISTEMA
:: ========================================

echo === VERIFICACIONES DE SISTEMA ===
echo.

:: 1. Verificar version de Windows
echo 1. Version de Windows:
for /f "tokens=4-5 delims=. " %%i in ('ver') do set VERSION=%%i.%%j
echo    Windows %VERSION%
if "%VERSION%" lss "10.0" (
    echo    [ERROR] Se requiere Windows 10 o superior
    set /a ERROR_COUNT+=1
) else (
    echo    [OK] Version compatible
)

:: 2. Verificar espacio en disco
echo.
echo 2. Espacio en disco C:\:
for /f "tokens=3" %%a in ('dir C:\ /-c ^| find "bytes free"') do set FREE_SPACE=%%a
set /a FREE_GB=%FREE_SPACE:~0,-9%
echo    Espacio libre: %FREE_GB% GB
if %FREE_GB% lss 5 (
    echo    [ERROR] Poco espacio en disco (menos de 5 GB)
    set /a ERROR_COUNT+=1
) else if %FREE_GB% lss 10 (
    echo    [AVISO] Espacio limitado (menos de 10 GB)
    set /a WARNING_COUNT+=1
) else (
    echo    [OK] Espacio suficiente
)

:: 3. Verificar memoria RAM
echo.
echo 3. Memoria RAM:
for /f "tokens=2 delims=:" %%a in ('systeminfo ^| find "Total Physical Memory"') do set TOTAL_RAM=%%a
echo    RAM total:%TOTAL_RAM%
echo    [INFO] Verificacion manual requerida (minimo 8 GB recomendado)

echo.

:: ========================================
:: VERIFICACIONES DE DOCKER
:: ========================================

echo === VERIFICACIONES DE DOCKER ===
echo.

:: 4. Verificar Docker instalado
echo 4. Docker Desktop:
docker --version >nul 2>&1
if %errorlevel% neq 0 (
    echo    [ERROR] Docker no instalado o no accesible
    set /a ERROR_COUNT+=1
) else (
    docker --version
    echo    [OK] Docker instalado
)

:: 5. Verificar Docker corriendo
echo.
echo 5. Estado de Docker:
docker info >nul 2>&1
if %errorlevel% neq 0 (
    echo    [ERROR] Docker no esta corriendo
    echo    [INFO] Inicie Docker Desktop
    set /a ERROR_COUNT+=1
) else (
    echo    [OK] Docker corriendo

    :: Mostrar informacion adicional
    for /f "tokens=2 delims=:" %%a in ('docker info ^| find "Total Memory"') do echo    RAM asignada:%%a
    for /f "tokens=2 delims=:" %%a in ('docker info ^| find "CPUs"') do echo    CPUs asignadas:%%a
)

:: 6. Verificar Docker Compose
echo.
echo 6. Docker Compose:
docker compose version >nul 2>&1
if %errorlevel% neq 0 (
    echo    [ERROR] Docker Compose no funciona
    set /a ERROR_COUNT+=1
) else (
    docker compose version
    echo    [OK] Docker Compose funcionando
)

echo.

:: ========================================
:: VERIFICACIONES DE ACMA
:: ========================================

echo === VERIFICACIONES DE ACMA ===
echo.

:: 7. Verificar archivos del proyecto
echo 7. Archivos del proyecto:
if not exist "docker-compose.yml" (
    echo    [ERROR] docker-compose.yml no encontrado
    echo    [INFO] Ejecutar desde directorio correcto: C:\ACMA\docker\
    set /a ERROR_COUNT+=1
) else (
    echo    [OK] docker-compose.yml encontrado
)

if not exist ".env" (
    echo    [ERROR] .env no encontrado
    echo    [INFO] Ejecutar configurar-postgres.bat
    set /a ERROR_COUNT+=1
) else (
    echo    [OK] .env encontrado
)

if not exist "start-server.bat" (
    echo    [ERROR] start-server.bat no encontrado
    set /a ERROR_COUNT+=1
) else (
    echo    [OK] start-server.bat encontrado
)

:: 8. Verificar servicios ACMA
echo.
echo 8. Servicios ACMA:
docker compose ps >nul 2>&1
if %errorlevel% neq 0 (
    echo    [AVISO] No se pudo verificar estado de servicios
    echo    [INFO] Servicios probablemente no iniciados
    set /a WARNING_COUNT+=1
) else (
    echo    Estado de servicios:
    docker compose ps

    :: Verificar servicios especificos
    docker compose ps | find "Up" | find "db" >nul
    if %errorlevel% equ 0 (
        echo    [OK] PostgreSQL corriendo
    ) else (
        echo    [ERROR] PostgreSQL no corriendo
        set /a ERROR_COUNT+=1
    )

    docker compose ps | find "Up" | find "web" >nul
    if %errorlevel% equ 0 (
        echo    [OK] Aplicacion Rails corriendo
    ) else (
        echo    [AVISO] Aplicacion Rails no corriendo
        set /a WARNING_COUNT+=1
    )
)

echo.

:: ========================================
:: VERIFICACIONES DE RED
:: ========================================

echo === VERIFICACIONES DE RED ===
echo.

:: 9. Verificar IP del servidor
echo 9. Configuracion de red:
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /c:"IPv4"') do (
    set IP=%%a
    set IP=!IP: =!
    goto :ip_found
)
:ip_found
echo    IP del servidor: %IP%

:: Verificar IP en .env
if exist ".env" (
    findstr "RAILS_HOST" .env >nul
    if %errorlevel% equ 0 (
        for /f "tokens=2 delims==" %%a in ('findstr "RAILS_HOST" .env') do set CONFIG_IP=%%a
        echo    IP configurada: %CONFIG_IP%
        if "%IP%" neq "%CONFIG_IP%" (
            echo    [AVISO] IP real y configurada no coinciden
            set /a WARNING_COUNT+=1
        ) else (
            echo    [OK] IP configurada correctamente
        )
    )
)

:: 10. Verificar puerto 3000
echo.
echo 10. Puerto 3000:
netstat -an | findstr ":3000" | findstr "LISTENING" >nul
if %errorlevel% equ 0 (
    echo    [OK] Puerto 3000 en uso (servidor probablemente corriendo)
) else (
    echo    [INFO] Puerto 3000 libre
)

:: 11. Verificar Firewall
echo.
echo 11. Windows Firewall:
netsh advfirewall firewall show rule name="ACMA Server" >nul 2>&1
if %errorlevel% equ 0 (
    echo    [OK] Regla de firewall configurada
) else (
    echo    [AVISO] Regla de firewall no encontrada
    echo    [INFO] Ejecutar: netsh advfirewall firewall add rule name="ACMA Server" dir=in action=allow protocol=TCP localport=3000
    set /a WARNING_COUNT+=1
)

echo.

:: ========================================
:: VERIFICACIONES DE CONECTIVIDAD
:: ========================================

echo === VERIFICACIONES DE CONECTIVIDAD ===
echo.

:: 12. Verificar acceso local
echo 12. Conectividad local:
curl -s http://localhost:3000 >nul 2>&1
if %errorlevel% equ 0 (
    echo    [OK] Servidor accesible en localhost:3000
) else (
    echo    [ERROR] Servidor no accesible localmente
    set /a ERROR_COUNT+=1
)

:: 13. Verificar acceso por IP
echo.
echo 13. Conectividad por IP:
if defined IP (
    curl -s http://%IP%:3000 >nul 2>&1
    if %errorlevel% equ 0 (
        echo    [OK] Servidor accesible en %IP%:3000
    ) else (
        echo    [ERROR] Servidor no accesible por IP
        set /a ERROR_COUNT+=1
    )
)

echo.

:: ========================================
:: VERIFICACIONES DE BACKUP
:: ========================================

echo === VERIFICACIONES DE BACKUP ===
echo.

:: 14. Verificar directorio de backups
echo 14. Sistema de backups:
if not exist "backups" (
    echo    [AVISO] Directorio de backups no existe
    echo    [INFO] Se creara automaticamente en el primer backup
    set /a WARNING_COUNT+=1
) else (
    echo    [OK] Directorio de backups existe

    :: Contar backups
    set BACKUP_COUNT=0
    for %%f in (backups\backup_acma_*) do set /a BACKUP_COUNT+=1
    echo    Backups encontrados: %BACKUP_COUNT%

    if %BACKUP_COUNT% equ 0 (
        echo    [AVISO] No hay backups creados
        echo    [INFO] Ejecutar backup-database.bat
        set /a WARNING_COUNT+=1
    ) else (
        echo    [OK] Backups disponibles

        :: Mostrar ultimo backup
        for /f "delims=" %%a in ('dir /b /o-d backups\backup_acma_* 2^>nul ^| head -1') do (
            echo    Ultimo backup: %%a
        )
    )
)

:: 15. Verificar tareas programadas
echo.
echo 15. Tareas automaticas:
schtasks /query /tn "ACMA*" >nul 2>&1
if %errorlevel% equ 0 (
    echo    [OK] Tareas automaticas configuradas
    schtasks /query /tn "ACMA*" /fo list | findstr "TaskName"
) else (
    echo    [AVISO] No hay tareas automaticas configuradas
    echo    [INFO] Ejecutar auto-start-setup.bat y backup-scheduler.bat
    set /a WARNING_COUNT+=1
)

echo.

:: ========================================
:: RESUMEN FINAL
:: ========================================

echo ===============================================
echo               RESUMEN DIAGNOSTICO
echo ===============================================
echo.

if %ERROR_COUNT% equ 0 (
    if %WARNING_COUNT% equ 0 (
        echo [OK] SISTEMA PERFECTO - Todo funcionando correctamente
        echo.
        echo ✅ Servidor ACMA operativo al 100%%
        echo ✅ Todos los componentes funcionando
        echo ✅ Sin problemas detectados
    ) else (
        echo [OK] SISTEMA FUNCIONAL - Advertencias menores
        echo.
        echo ✅ Servidor ACMA funcionando
        echo ⚠️  %WARNING_COUNT% advertencia(s) detectada(s)
        echo ℹ️  Revisar puntos marcados con [AVISO]
    )
) else (
    echo [ERROR] PROBLEMAS DETECTADOS - Requiere atencion
    echo.
    echo ❌ %ERROR_COUNT% error(es) critico(s)
    echo ⚠️  %WARNING_COUNT% advertencia(s)
    echo.
    echo ACCION REQUERIDA:
    echo 1. Revisar todos los puntos marcados con [ERROR]
    echo 2. Seguir las instrucciones [INFO] para solucionarlos
    echo 3. Re-ejecutar este verificador
)

echo.
echo Informacion del sistema:
echo - Fecha verificacion: %date% %time%
echo - Ubicacion: %CD%
echo - Usuario: %USERNAME%
echo - Computadora: %COMPUTERNAME%

echo.
echo URLs de acceso:
echo - Local: http://localhost:3000
if defined IP echo - Red: http://%IP%:3000

echo.
echo Comandos utiles:
echo - Iniciar servidor: start-server.bat
echo - Ver logs: docker compose logs -f
echo - Estado servicios: docker compose ps
echo - Crear backup: backup-database.bat

echo.
echo ===============================================
echo.
pause
