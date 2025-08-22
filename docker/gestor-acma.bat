@echo off
title Gestor de Servicios ACMA
color 0A
cls

:main_menu
cls
echo.
echo  █████╗  ██████╗███╗   ███╗ █████╗
echo ██╔══██║██╔════╝████╗ ████║██╔══██╗
echo ███████║██║     ██╔████╔██║███████║
echo ██║  ██║██║     ██║╚██╔╝██║██╔══██║
echo ██║  ██║╚██████╗██║ ╚═╝ ██║██║  ██║
echo ╚═╝  ╚═╝ ╚═════╝╚═╝     ╚═╝╚═╝  ╚═╝
echo.
echo         GESTOR DE SERVICIOS ACMA
echo ===============================================
echo.
echo [1] Iniciar Servidor
echo [2] Detener Servidor
echo [3] Reiniciar Servidor
echo [4] Estado de Servicios
echo [5] Ver Logs en Tiempo Real
echo [6] Monitor del Sistema
echo [7] Verificar Configuracion
echo [8] Crear Backup
echo [9] Restaurar Backup
echo [A] Configurar Inicio Automatico
echo [B] Configurar Backups Automaticos
echo [C] Abrir en Navegador
echo [D] Configuracion de Red
echo [0] Salir
echo.
echo ===============================================

set /p choice="Seleccione una opcion: "

if "%choice%"=="1" goto start_server
if "%choice%"=="2" goto stop_server
if "%choice%"=="3" goto restart_server
if "%choice%"=="4" goto status_server
if "%choice%"=="5" goto logs_server
if "%choice%"=="6" goto monitor_server
if "%choice%"=="7" goto verify_server
if "%choice%"=="8" goto backup_db
if "%choice%"=="9" goto restore_db
if "%choice%"=="a" goto setup_autostart
if "%choice%"=="A" goto setup_autostart
if "%choice%"=="b" goto setup_backups
if "%choice%"=="B" goto setup_backups
if "%choice%"=="c" goto open_browser
if "%choice%"=="C" goto open_browser
if "%choice%"=="d" goto network_config
if "%choice%"=="D" goto network_config
if "%choice%"=="0" goto exit_program

echo.
echo [ERROR] Opcion no valida
pause
goto main_menu

:start_server
cls
echo.
echo ===============================================
echo              INICIANDO SERVIDOR
echo ===============================================
echo.
echo Iniciando servicios Docker...
docker compose up -d
echo.
echo ✅ Servidor iniciado
echo.
echo URLs de acceso:
echo - Local: http://localhost:3000
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /c:"IPv4"') do (
    set IP=%%a
    set IP=!IP: =!
    echo - Red: http://!IP!:3000
    goto :ip_done1
)
:ip_done1
echo.
pause
goto main_menu

:stop_server
cls
echo.
echo ===============================================
echo              DETENIENDO SERVIDOR
echo ===============================================
echo.
echo Deteniendo servicios Docker...
docker compose down
echo.
echo ✅ Servidor detenido
echo.
pause
goto main_menu

:restart_server
cls
echo.
echo ===============================================
echo             REINICIANDO SERVIDOR
echo ===============================================
echo.
echo Reiniciando servicios Docker...
docker compose restart
echo.
echo ✅ Servidor reiniciado
echo.
pause
goto main_menu

:status_server
cls
echo.
echo ===============================================
echo             ESTADO DE SERVICIOS
echo ===============================================
echo.
docker compose ps
echo.
echo Estado de puertos:
netstat -an | findstr ":3000"
echo.
echo Estado de conectividad:
curl -s --max-time 3 http://localhost:3000 >nul 2>&1
if %errorlevel% equ 0 (
    echo ✅ Servidor accesible localmente
) else (
    echo ❌ Servidor no accesible
)
echo.
pause
goto main_menu

:logs_server
cls
echo.
echo ===============================================
echo             LOGS EN TIEMPO REAL
echo ===============================================
echo.
echo Presiona Ctrl+C para volver al menu
echo.
pause
docker compose logs -f
goto main_menu

:monitor_server
cls
echo.
echo ===============================================
echo            MONITOR DEL SISTEMA
echo ===============================================
echo.
echo Abriendo monitor en tiempo real...
echo Presiona Ctrl+C en la ventana del monitor para volver
echo.
pause
start "" cmd /c "monitor-servidor.bat"
goto main_menu

:verify_server
cls
echo.
echo ===============================================
echo           VERIFICAR CONFIGURACION
echo ===============================================
echo.
verificar-servidor.bat
echo.
pause
goto main_menu

:backup_db
cls
echo.
echo ===============================================
echo              CREAR BACKUP
echo ===============================================
echo.
backup-database.bat
echo.
pause
goto main_menu

:restore_db
cls
echo.
echo ===============================================
echo             RESTAURAR BACKUP
echo ===============================================
echo.
echo Backups disponibles:
if exist "backups" (
    dir /b backups\*.sql.gz 2>nul || echo No hay backups disponibles
) else (
    echo Directorio de backups no existe
)
echo.
echo ¿Continuar con la restauracion? (S/N)
set /p confirm="Respuesta: "
if /i "%confirm%"=="S" (
    restore-database.bat
) else (
    echo Operacion cancelada
)
echo.
pause
goto main_menu

:setup_autostart
cls
echo.
echo ===============================================
echo         CONFIGURAR INICIO AUTOMATICO
echo ===============================================
echo.
auto-start-setup.bat
echo.
pause
goto main_menu

:setup_backups
cls
echo.
echo ===============================================
echo        CONFIGURAR BACKUPS AUTOMATICOS
echo ===============================================
echo.
backup-scheduler.bat
echo.
pause
goto main_menu

:open_browser
cls
echo.
echo ===============================================
echo            ABRIR EN NAVEGADOR
echo ===============================================
echo.
echo Abriendo ACMA en el navegador...
start http://localhost:3000
echo.
echo ✅ Navegador abierto
echo.
pause
goto main_menu

:network_config
cls
echo.
echo ===============================================
echo           CONFIGURACION DE RED
echo ===============================================
echo.
echo IP actual del servidor:
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /c:"IPv4"') do (
    set IP=%%a
    set IP=!IP: =!
    echo !IP!
)

echo.
echo IP configurada en .env:
if exist ".env" (
    findstr "RAILS_HOST" .env 2>nul || echo No configurada
) else (
    echo Archivo .env no existe
)

echo.
echo Reglas de firewall:
netsh advfirewall firewall show rule name="ACMA Server" 2>nul || echo No configurada

echo.
echo [1] Actualizar IP en configuracion
echo [2] Configurar firewall
echo [3] Volver al menu principal
echo.
set /p net_choice="Seleccione opcion: "

if "%net_choice%"=="1" (
    echo.
    set /p new_ip="Ingrese la nueva IP: "
    echo RAILS_HOST=!new_ip! >> .env.tmp
    findstr /v "RAILS_HOST" .env >> .env.tmp 2>nul
    move .env.tmp .env >nul
    echo ✅ IP actualizada a !new_ip!
)

if "%net_choice%"=="2" (
    echo.
    echo Configurando firewall...
    netsh advfirewall firewall add rule name="ACMA Server" dir=in action=allow protocol=TCP localport=3000
    echo ✅ Firewall configurado
)

echo.
pause
goto main_menu

:exit_program
cls
echo.
echo ===============================================
echo                  SALIENDO
echo ===============================================
echo.
echo ¡Gracias por usar ACMA!
echo.
timeout /t 2 /nobreak >nul
exit /b 0
