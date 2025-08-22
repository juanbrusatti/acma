@echo off
title Configurador de Arranque Automatico - ACMA Server
cls

echo.
echo ===============================================
echo    CONFIGURADOR DE ARRANQUE AUTOMATICO
echo ===============================================
echo.
echo Este script configurara el servidor ACMA para que se
echo inicie automaticamente al encender la PC.
echo.
echo Opciones disponibles:
echo 1) Configurar arranque automatico (Programador de Tareas)
echo 2) Configurar como servicio Windows (Avanzado)
echo 3) Solo crear acceso directo en Inicio
echo 4) Remover arranque automatico
echo 5) Ver estado actual
echo 6) Cancelar
echo.
set /p opcion="Selecciona una opcion (1-6): "

if "%opcion%"=="1" goto tarea_programada
if "%opcion%"=="2" goto servicio_windows
if "%opcion%"=="3" goto acceso_directo
if "%opcion%"=="4" goto remover_arranque
if "%opcion%"=="5" goto ver_estado
if "%opcion%"=="6" goto cancelar
goto menu

:tarea_programada
echo.
echo CONFIGURANDO TAREA PROGRAMADA
echo.
echo Verificando permisos de administrador...
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Se requieren permisos de administrador
    echo         Ejecute este script como administrador
    pause
    goto fin
)

echo Creando tarea programada...
echo.

:: Crear la tarea programada
schtasks /create /tn "ACMA Server Startup" /tr "%CD%\start-server.bat" /sc onstart /ru SYSTEM /rl HIGHEST /f >nul

if %errorlevel% equ 0 (
    echo [OK] Tarea programada creada exitosamente.
    echo.
    echo El servidor ACMA se iniciara automaticamente al encender la PC.
    echo.
    echo Para gestionar la tarea:
    echo - Ver: schtasks /query /tn "ACMA Server Startup"
    echo - Deshabilitar: schtasks /change /tn "ACMA Server Startup" /disable
    echo - Eliminar: schtasks /delete /tn "ACMA Server Startup" /f
    echo.
    echo O usar el Programador de tareas (taskschd.msc):
    echo - Buscar "ACMA Server Startup"
    echo - Click derecho para opciones
) else (
    echo [ERROR] No se pudo crear la tarea programada.
    echo         Verifique permisos de administrador.
)
echo.
pause
goto fin

:servicio_windows
echo.
echo CONFIGURANDO SERVICIO WINDOWS
echo.
echo ATENCION: Este metodo requiere NSSM (Non-Sucking Service Manager)
echo.

:: Verificar si NSSM existe
if not exist "nssm.exe" (
    echo NSSM no encontrado. Descargando...

    :: Crear directorio temporal
    if not exist "%TEMP%\nssm" mkdir "%TEMP%\nssm"
    cd /d "%TEMP%\nssm"

    :: Descargar NSSM
    powershell -Command "Invoke-WebRequest -Uri 'https://nssm.cc/release/nssm-2.24.zip' -OutFile 'nssm.zip'"
    powershell -Command "Expand-Archive -Path 'nssm.zip' -DestinationPath '.'"

    :: Copiar ejecutable
    copy "nssm-2.24\win64\nssm.exe" "%~dp0" >nul

    :: Limpiar
    cd /d "%~dp0"
    rmdir /s /q "%TEMP%\nssm"

    if exist "nssm.exe" (
        echo [OK] NSSM descargado exitosamente
    ) else (
        echo [ERROR] No se pudo descargar NSSM
        echo         Descargue manualmente desde: https://nssm.cc/download
        pause
        goto fin
    )
)

echo.
set /p continuar="¿Continuar con la instalacion del servicio? (s/N): "
if /i not "%continuar%"=="s" goto fin

:: Verificar permisos de administrador
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Se requieren permisos de administrador
    pause
    goto fin
)

:: Instalar el servicio
echo Instalando servicio Windows...
nssm install "ACMA Server" "%CD%\start-server.bat"
nssm set "ACMA Server" AppDirectory "%CD%"
nssm set "ACMA Server" DisplayName "Servidor ACMA"
nssm set "ACMA Server" Description "Servidor de aplicacion ACMA con Docker y PostgreSQL"
nssm set "ACMA Server" Start SERVICE_AUTO_START

echo.
echo [OK] Servicio instalado exitosamente.
echo.
echo Para gestionar el servicio:
echo - Iniciar: net start "ACMA Server"
echo - Parar:   net stop "ACMA Server"
echo - Estado:  sc query "ACMA Server"
echo - Configurar: services.msc (buscar "Servidor ACMA")
echo.
pause
goto fin

:acceso_directo
echo.
echo CREANDO ACCESO DIRECTO EN INICIO
echo.
echo Creando acceso directo en carpeta de Inicio...

:: Crear acceso directo en startup
powershell -Command "$WshShell = New-Object -comObject WScript.Shell; $Shortcut = $WshShell.CreateShortcut('%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\ACMA Server.lnk'); $Shortcut.TargetPath = '%CD%\start-server.bat'; $Shortcut.WorkingDirectory = '%CD%'; $Shortcut.Description = 'Servidor ACMA'; $Shortcut.Save()"

if %errorlevel% equ 0 (
    echo [OK] Acceso directo creado en la carpeta de Inicio.
    echo.
    echo El servidor se iniciara cuando el usuario inicie sesion.
    echo.
    echo Ubicacion: %APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\
    echo Archivo: ACMA Server.lnk
    echo.
    echo Para deshabilitarlo:
    echo - Eliminar el archivo "ACMA Server.lnk" de la carpeta Startup
    echo - O presionar Win+R, escribir "shell:startup" y eliminar el acceso directo
) else (
    echo [ERROR] No se pudo crear el acceso directo.
)
echo.
pause
goto fin

:remover_arranque
echo.
echo REMOVIENDO ARRANQUE AUTOMATICO
echo.
echo Buscando configuraciones de arranque automatico...

:: Verificar tarea programada
schtasks /query /tn "ACMA Server Startup" >nul 2>&1
if %errorlevel% equ 0 (
    echo Encontrada tarea programada. Eliminando...
    schtasks /delete /tn "ACMA Server Startup" /f >nul
    if %errorlevel% equ 0 (
        echo [OK] Tarea programada eliminada
    ) else (
        echo [ERROR] No se pudo eliminar tarea programada
    )
)

:: Verificar servicio
sc query "ACMA Server" >nul 2>&1
if %errorlevel% equ 0 (
    echo Encontrado servicio Windows. Eliminando...
    net stop "ACMA Server" >nul 2>&1
    sc delete "ACMA Server" >nul
    if %errorlevel% equ 0 (
        echo [OK] Servicio eliminado
    ) else (
        echo [ERROR] No se pudo eliminar servicio
    )
)

:: Verificar acceso directo
if exist "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\ACMA Server.lnk" (
    echo Encontrado acceso directo en Startup. Eliminando...
    del "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\ACMA Server.lnk" >nul
    if %errorlevel% equ 0 (
        echo [OK] Acceso directo eliminado
    ) else (
        echo [ERROR] No se pudo eliminar acceso directo
    )
)

echo.
echo [OK] Arranque automatico removido
echo     El servidor ya no se iniciara automaticamente
echo.
pause
goto fin

:ver_estado
echo.
echo ESTADO ACTUAL DEL ARRANQUE AUTOMATICO
echo.

:: Verificar tarea programada
echo Verificando tarea programada...
schtasks /query /tn "ACMA Server Startup" >nul 2>&1
if %errorlevel% equ 0 (
    echo [OK] Tarea programada activa: "ACMA Server Startup"
    schtasks /query /tn "ACMA Server Startup" /fo table
) else (
    echo [--] No hay tarea programada configurada
)

echo.
:: Verificar servicio
echo Verificando servicio Windows...
sc query "ACMA Server" >nul 2>&1
if %errorlevel% equ 0 (
    echo [OK] Servicio Windows activo: "ACMA Server"
    sc query "ACMA Server"
) else (
    echo [--] No hay servicio Windows configurado
)

echo.
:: Verificar acceso directo
echo Verificando acceso directo en Startup...
if exist "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\ACMA Server.lnk" (
    echo [OK] Acceso directo en Startup: ACMA Server.lnk
) else (
    echo [--] No hay acceso directo en Startup
)

echo.
pause
goto fin

:cancelar
echo.
echo Operacion cancelada.
pause
goto fin

:fin
cls
echo.
echo ===============================================
echo           CONFIGURACION COMPLETADA
echo ===============================================
echo.
echo Instrucciones para verificar:
echo.
echo 1. Reinicie la PC para probar el arranque automatico
echo 2. El servidor estara disponible en: http://IP:3000
echo 3. Verifique los logs con: docker compose logs -f
echo.
echo Para gestionar el arranque automatico:
echo - Programador de tareas: taskschd.msc
echo - Servicios: services.msc
echo - Startup: shell:startup
echo.
pause
