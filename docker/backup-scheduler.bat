@echo off
title Programador de Backups ACMA
cls

echo.
echo ===============================================
echo       PROGRAMADOR DE BACKUPS AUTOMATICOS
echo ===============================================
echo.
echo Este script configurara backups automaticos del servidor ACMA
echo usando el Programador de tareas de Windows.
echo.

:: Verificar permisos de administrador
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Este script debe ejecutarse como Administrador
    echo.
    pause
    exit /b 1
)

echo Opciones de programacion:
echo.
echo 1) Backup diario a las 2:00 AM (Recomendado)
echo 2) Backup diario a horario personalizado
echo 3) Backup semanal (Domingos)
echo 4) Ver tareas de backup existentes
echo 5) Eliminar tareas de backup
echo 6) Cancelar
echo.
set /p opcion="Seleccione una opcion (1-6): "

if "%opcion%"=="1" goto backup_diario_2am
if "%opcion%"=="2" goto backup_personalizado
if "%opcion%"=="3" goto backup_semanal
if "%opcion%"=="4" goto ver_tareas
if "%opcion%"=="5" goto eliminar_tareas
if "%opcion%"=="6" goto cancelar
goto menu

:backup_diario_2am
echo.
echo CONFIGURANDO BACKUP DIARIO A LAS 2:00 AM
echo.

:: Crear script de backup automatico
echo @echo off > backup_auto.bat
echo title Backup Automatico ACMA >> backup_auto.bat
echo cd /d "%CD%" >> backup_auto.bat
echo echo 4 ^| backup-database.bat >> backup_auto.bat
echo echo Backup automatico completado ^> backup_auto.log >> backup_auto.bat
echo date /t ^>^> backup_auto.log >> backup_auto.bat
echo time /t ^>^> backup_auto.log >> backup_auto.bat

:: Crear tarea programada
schtasks /create /tn "ACMA Backup Diario" /tr "%CD%\backup_auto.bat" /sc daily /st 02:00 /ru SYSTEM /f >nul

if %errorlevel% equ 0 (
    echo [OK] Backup diario programado exitosamente
    echo.
    echo Configuracion:
    echo - Horario: Todos los dias a las 2:00 AM
    echo - Tipo: Backup automatico comprimido (opcion 4)
    echo - Ubicacion: %CD%\backups\
    echo - Log: %CD%\backup_auto.log
) else (
    echo [ERROR] No se pudo crear la tarea programada
)
goto continuar

:backup_personalizado
echo.
echo CONFIGURANDO BACKUP DIARIO PERSONALIZADO
echo.
set /p hora="Ingrese la hora (formato 24h, ej: 14:30): "

:: Validar formato de hora
echo %hora% | findstr /r "^[0-2][0-9]:[0-5][0-9]$" >nul
if %errorlevel% neq 0 (
    echo [ERROR] Formato de hora invalido. Use HH:MM (ej: 14:30)
    pause
    goto fin
)

:: Crear script de backup automatico
echo @echo off > backup_auto.bat
echo title Backup Automatico ACMA >> backup_auto.bat
echo cd /d "%CD%" >> backup_auto.bat
echo echo 4 ^| backup-database.bat >> backup_auto.bat
echo echo Backup automatico completado ^> backup_auto.log >> backup_auto.bat
echo date /t ^>^> backup_auto.log >> backup_auto.bat
echo time /t ^>^> backup_auto.log >> backup_auto.bat

:: Crear tarea programada
schtasks /create /tn "ACMA Backup Diario" /tr "%CD%\backup_auto.bat" /sc daily /st %hora% /ru SYSTEM /f >nul

if %errorlevel% equ 0 (
    echo [OK] Backup diario programado exitosamente
    echo.
    echo Configuracion:
    echo - Horario: Todos los dias a las %hora%
    echo - Tipo: Backup automatico comprimido
    echo - Ubicacion: %CD%\backups\
) else (
    echo [ERROR] No se pudo crear la tarea programada
)
goto continuar

:backup_semanal
echo.
echo CONFIGURANDO BACKUP SEMANAL
echo.
set /p hora="Ingrese la hora para el backup semanal (ej: 03:00): "

:: Crear script de backup completo
echo @echo off > backup_semanal.bat
echo title Backup Semanal ACMA >> backup_semanal.bat
echo cd /d "%CD%" >> backup_semanal.bat
echo echo 1 ^| backup-database.bat >> backup_semanal.bat
echo echo Backup semanal completado ^> backup_semanal.log >> backup_semanal.bat
echo date /t ^>^> backup_semanal.log >> backup_semanal.bat
echo time /t ^>^> backup_semanal.log >> backup_semanal.bat

:: Crear tarea programada semanal
schtasks /create /tn "ACMA Backup Semanal" /tr "%CD%\backup_semanal.bat" /sc weekly /d SUN /st %hora% /ru SYSTEM /f >nul

if %errorlevel% equ 0 (
    echo [OK] Backup semanal programado exitosamente
    echo.
    echo Configuracion:
    echo - Horario: Domingos a las %hora%
    echo - Tipo: Backup completo (SQL + archivos + config)
    echo - Ubicacion: %CD%\backups\
) else (
    echo [ERROR] No se pudo crear la tarea programada
)
goto continuar

:ver_tareas
echo.
echo TAREAS DE BACKUP EXISTENTES
echo.
echo Buscando tareas relacionadas con ACMA...
echo.

:: Mostrar tareas de backup
schtasks /query /tn "ACMA Backup*" /fo table 2>nul
if %errorlevel% neq 0 (
    echo [INFO] No se encontraron tareas de backup programadas
) else (
    echo.
    echo Para ver detalles de una tarea:
    echo schtasks /query /tn "NOMBRE_TAREA" /v
    echo.
    echo Para ejecutar manualmente:
    echo schtasks /run /tn "NOMBRE_TAREA"
)

:: Mostrar logs de backup si existen
echo.
if exist "backup_auto.log" (
    echo Ultimo backup automatico:
    type backup_auto.log | find /v ""
)
if exist "backup_semanal.log" (
    echo.
    echo Ultimo backup semanal:
    type backup_semanal.log | find /v ""
)

pause
goto fin

:eliminar_tareas
echo.
echo ELIMINAR TAREAS DE BACKUP
echo.
echo Tareas encontradas:
schtasks /query /tn "ACMA Backup*" /fo list 2>nul | findstr "TaskName"

echo.
set /p confirmar="¿Eliminar TODAS las tareas de backup ACMA? (s/N): "
if /i not "%confirmar%"=="s" goto fin

:: Eliminar tareas
schtasks /delete /tn "ACMA Backup Diario" /f >nul 2>&1
schtasks /delete /tn "ACMA Backup Semanal" /f >nul 2>&1

echo [OK] Tareas de backup eliminadas
echo.

:: Eliminar archivos auxiliares
if exist "backup_auto.bat" del "backup_auto.bat" >nul
if exist "backup_semanal.bat" del "backup_semanal.bat" >nul

echo Scripts auxiliares eliminados
goto fin

:continuar
echo.
echo ===============================================
echo        CONFIGURACION ADICIONAL
echo ===============================================
echo.

:: Configurar limpieza automatica de backups antiguos
set /p limpieza="¿Configurar limpieza automatica de backups antiguos? (s/N): "
if /i "%limpieza%"=="s" (
    echo.
    set /p dias="¿Despues de cuantos dias eliminar backups? (recomendado: 30): "
    if "%dias%"=="" set dias=30

    :: Crear script de limpieza
    echo @echo off > limpiar_backups.bat
    echo title Limpieza Automatica Backups ACMA >> limpiar_backups.bat
    echo cd /d "%CD%" >> limpiar_backups.bat
    echo forfiles /p backups /s /m backup_acma_*.* /d -%dias% /c "cmd /c del @path" 2^>nul >> limpiar_backups.bat
    echo echo Limpieza completada ^> limpieza.log >> limpiar_backups.bat
    echo date /t ^>^> limpieza.log >> limpiar_backups.bat

    :: Programar limpieza semanal
    schtasks /create /tn "ACMA Limpieza Backups" /tr "%CD%\limpiar_backups.bat" /sc weekly /d MON /st 01:00 /ru SYSTEM /f >nul

    if %errorlevel% equ 0 (
        echo [OK] Limpieza automatica configurada
        echo      Se eliminaran backups de mas de %dias% dias
        echo      Horario: Lunes a la 1:00 AM
    )
)

echo.
echo ===============================================
echo         PROGRAMACION COMPLETADA
echo ===============================================
echo.
echo Configuracion final:
echo.

:: Mostrar resumen de tareas
schtasks /query /tn "ACMA*" /fo table 2>nul

echo.
echo Ubicaciones importantes:
echo - Backups: %CD%\backups\
echo - Logs: %CD%\backup_auto.log
echo - Scripts: %CD%\backup_auto.bat
echo.
echo Para gestionar tareas:
echo - Programador de tareas: taskschd.msc
echo - Ver logs: type backup_auto.log
echo - Ejecutar manual: schtasks /run /tn "ACMA Backup Diario"
echo.
goto fin

:cancelar
echo Operacion cancelada.
goto fin

:fin
pause
