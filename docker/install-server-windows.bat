@echo off
title Instalador Automatico ACMA Server para Windows
cls

echo.
echo ===============================================
echo    INSTALADOR AUTOMATICO ACMA SERVER
echo ===============================================
echo.
echo Este script instalara automaticamente:
echo - Docker Desktop para Windows
echo - Configuracion inicial del servidor ACMA
echo - Scripts de operacion y mantenimiento
echo.
echo ATENCION: Se requieren permisos de administrador
echo.
pause

:: Verificar permisos de administrador
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Este script debe ejecutarse como Administrador
    echo.
    echo Para ejecutar como administrador:
    echo 1. Click derecho en el archivo
    echo 2. Seleccionar "Ejecutar como administrador"
    echo.
    pause
    exit /b 1
)

echo [OK] Permisos de administrador verificados
echo.

:: Verificar version de Windows
for /f "tokens=4-5 delims=. " %%i in ('ver') do set VERSION=%%i.%%j
echo Version de Windows detectada: %VERSION%

:: Verificar si es Windows 10/11
if "%VERSION%" lss "10.0" (
    echo [ERROR] Se requiere Windows 10 o superior
    echo         Version actual: %VERSION%
    pause
    exit /b 1
)

echo [OK] Version de Windows compatible
echo.

:: Verificar si Hyper-V esta habilitado
echo Verificando Hyper-V...
dism /online /get-featureinfo /featurename:Microsoft-Hyper-V >nul 2>&1
if %errorlevel% neq 0 (
    echo [AVISO] Hyper-V no esta habilitado
    echo.
    set /p habilitar="¿Desea habilitar Hyper-V ahora? (s/N): "
    if /i "!habilitar!"=="s" (
        echo Habilitando Hyper-V...
        dism /online /enable-feature /featurename:Microsoft-Hyper-V /all /norestart
        dism /online /enable-feature /featurename:Containers /all /norestart
        echo.
        echo [OK] Hyper-V habilitado
        echo [AVISO] Se requiere reiniciar Windows
        set /p reiniciar="¿Desea reiniciar ahora? (s/N): "
        if /i "!reiniciar!"=="s" (
            shutdown /r /t 10 /c "Reiniciando para completar instalacion de Hyper-V"
            exit /b 0
        ) else (
            echo [AVISO] Reinicie Windows manualmente antes de continuar
            pause
            exit /b 0
        )
    )
) else (
    echo [OK] Hyper-V ya esta habilitado
)

:: Verificar si Docker esta instalado
docker --version >nul 2>&1
if %errorlevel% neq 0 (
    echo.
    echo [INFO] Docker no detectado. Iniciando descarga...
    echo.

    :: Crear directorio temporal
    if not exist "%TEMP%\ACMA_Install" mkdir "%TEMP%\ACMA_Install"
    cd /d "%TEMP%\ACMA_Install"

    :: Descargar Docker Desktop
    echo Descargando Docker Desktop para Windows...
    powershell -Command "Invoke-WebRequest -Uri 'https://desktop.docker.com/win/main/amd64/Docker%%20Desktop%%20Installer.exe' -OutFile 'DockerDesktopInstaller.exe'"

    if exist "DockerDesktopInstaller.exe" (
        echo [OK] Docker Desktop descargado
        echo.
        echo Iniciando instalacion de Docker Desktop...
        echo NOTA: El instalador se abrira en una ventana separada
        echo       Siga las instrucciones del instalador
        echo.

        :: Ejecutar instalador
        start /wait DockerDesktopInstaller.exe install --quiet

        echo.
        echo [OK] Docker Desktop instalado
        echo.
        echo [AVISO] Se requiere reiniciar Windows para completar la instalacion
        set /p reiniciar="¿Desea reiniciar ahora? (s/N): "
        if /i "!reiniciar!"=="s" (
            shutdown /r /t 10 /c "Reiniciando para completar instalacion de Docker"
            exit /b 0
        ) else (
            echo [AVISO] Reinicie Windows y ejecute este script nuevamente
            pause
            exit /b 0
        )
    ) else (
        echo [ERROR] No se pudo descargar Docker Desktop
        echo         Descargue manualmente desde: https://www.docker.com/products/docker-desktop/
        pause
        exit /b 1
    )
) else (
    echo [OK] Docker ya esta instalado
    docker --version
)

:: Verificar que Docker este corriendo
echo.
echo Verificando que Docker este corriendo...
docker info >nul 2>&1
if %errorlevel% neq 0 (
    echo [AVISO] Docker no esta corriendo
    echo         Inicie Docker Desktop y ejecute este script nuevamente
    pause
    exit /b 1
)
echo [OK] Docker esta corriendo

:: Crear estructura de directorios
echo.
echo Creando estructura de directorios...
if not exist "C:\ACMA" mkdir "C:\ACMA"
if not exist "C:\ACMA\docker" mkdir "C:\ACMA\docker"
if not exist "C:\ACMA\backups" mkdir "C:\ACMA\backups"
echo [OK] Directorios creados

:: Configurar Firewall
echo.
echo Configurando Windows Firewall...
netsh advfirewall firewall delete rule name="ACMA Server" >nul 2>&1
netsh advfirewall firewall add rule name="ACMA Server" dir=in action=allow protocol=TCP localport=3000 >nul
if %errorlevel% equ 0 (
    echo [OK] Firewall configurado (puerto 3000 abierto)
) else (
    echo [AVISO] No se pudo configurar Firewall automaticamente
)

:: Obtener IP del servidor
echo.
echo Detectando IP del servidor...
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /c:"IPv4"') do (
    set IP=%%a
    set IP=!IP: =!
    goto :ip_found
)
:ip_found
echo IP detectada: %IP%

echo.
echo ===============================================
echo         INSTALACION COMPLETADA
echo ===============================================
echo.
echo Proximos pasos:
echo 1. Copie los archivos del proyecto ACMA a: C:\ACMA\docker\
echo 2. Configure la IP del servidor: %IP%
echo 3. Execute: C:\ACMA\docker\start-server.bat
echo.
echo Ubicacion de instalacion: C:\ACMA\
echo Puerto del servidor: 3000
echo IP del servidor: %IP%
echo URL completa: http://%IP%:3000
echo.
echo ===============================================
echo.
pause
