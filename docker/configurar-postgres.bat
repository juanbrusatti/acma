 @echo off
title Configurador de PostgreSQL para ACMA
cls

echo.
echo ===============================================
echo      CONFIGURADOR DE POSTGRESQL PARA ACMA
echo ===============================================
echo.

:: Verificar si existe el archivo .env
if not exist ".env" (
    echo [ERROR] No se encontro el archivo .env
    echo         Ejecute este script desde el directorio 'docker'
    echo.
    pause
    exit
)

echo Configuracion actual en .env:
echo.
type .env
echo.
echo ===============================================
echo.

set /p continue="¿Desea cambiar alguna configuracion? (s/N): "
if /i not "%continue%"=="s" goto :verificar

echo.
echo Configuraciones disponibles para cambiar:
echo.
echo 1. IP del servidor (actualmente en RAILS_HOST)
echo 2. Puerto del servidor (actualmente en RAILS_PORT)
echo 3. Contraseña de PostgreSQL (POSTGRES_PASSWORD)
echo 4. Nombre de la base de datos (POSTGRES_DB)
echo 5. Ver configuracion completa
echo 6. Reiniciar con valores por defecto
echo.

set /p opcion="Seleccione una opcion (1-6): "

if "%opcion%"=="1" goto :cambiar_ip
if "%opcion%"=="2" goto :cambiar_puerto
if "%opcion%"=="3" goto :cambiar_password
if "%opcion%"=="4" goto :cambiar_db
if "%opcion%"=="5" goto :mostrar_config
if "%opcion%"=="6" goto :resetear_config
goto :opcion_invalida

:cambiar_ip
echo.
echo IP actual del servidor:
for /f "tokens=2 delims==" %%a in ('findstr "RAILS_HOST" .env') do echo %%a
echo.
set /p nueva_ip="Ingrese la nueva IP del servidor: "
if "%nueva_ip%"=="" goto :cambiar_ip

:: Usar PowerShell para reemplazar la linea
powershell -Command "(Get-Content .env) -replace '^RAILS_HOST=.*', 'RAILS_HOST=%nueva_ip%' | Set-Content .env"
echo [OK] IP actualizada a: %nueva_ip%
goto :continuar

:cambiar_puerto
echo.
echo Puerto actual del servidor:
for /f "tokens=2 delims==" %%a in ('findstr "RAILS_PORT" .env') do echo %%a
echo.
set /p nuevo_puerto="Ingrese el nuevo puerto (3000 recomendado): "
if "%nuevo_puerto%"=="" set nuevo_puerto=3000

powershell -Command "(Get-Content .env) -replace '^RAILS_PORT=.*', 'RAILS_PORT=%nuevo_puerto%' | Set-Content .env"
echo [OK] Puerto actualizado a: %nuevo_puerto%
goto :continuar

:cambiar_password
echo.
echo ⚠️  CAMBIAR CONTRASEÑA DE POSTGRESQL
echo.
echo IMPORTANTE: Si ya tiene datos en PostgreSQL y cambia la contraseña,
echo            necesitara recrear la base de datos.
echo.
set /p confirmar="¿Esta seguro? (s/N): "
if /i not "%confirmar%"=="s" goto :continuar

set /p nueva_password="Ingrese la nueva contraseña (minimo 8 caracteres): "
if "%nueva_password%"=="" goto :cambiar_password

powershell -Command "(Get-Content .env) -replace '^POSTGRES_PASSWORD=.*', 'POSTGRES_PASSWORD=%nueva_password%' | Set-Content .env"
powershell -Command "(Get-Content .env) -replace '^DATABASE_URL=postgresql://postgres:.*@', 'DATABASE_URL=postgresql://postgres:%nueva_password%@' | Set-Content .env"
echo [OK] Contraseña actualizada
echo [AVISO] Reinicie completamente Docker para aplicar cambios
goto :continuar

:cambiar_db
echo.
echo Nombre actual de la base de datos:
for /f "tokens=2 delims==" %%a in ('findstr "POSTGRES_DB" .env') do echo %%a
echo.
set /p nueva_db="Ingrese el nuevo nombre de base de datos: "
if "%nueva_db%"=="" goto :cambiar_db

powershell -Command "(Get-Content .env) -replace '^POSTGRES_DB=.*', 'POSTGRES_DB=%nueva_db%' | Set-Content .env"
echo [OK] Base de datos actualizada a: %nueva_db%
goto :continuar

:mostrar_config
echo.
echo ===============================================
echo           CONFIGURACION COMPLETA
echo ===============================================
echo.
type .env
echo.
pause
goto :continuar

:resetear_config
echo.
echo ⚠️  RESETEAR CONFIGURACION
echo.
echo Esto restaurara los valores por defecto.
echo Los datos existentes NO se perderan.
echo.
set /p confirmar="¿Esta seguro? (s/N): "
if /i not "%confirmar%"=="s" goto :continuar

:: Crear archivo .env con valores por defecto
(
echo # Configuración de PostgreSQL para Docker
echo # Este archivo debe estar en el mismo directorio que docker-compose.yml
echo.
echo # Configuración de la base de datos PostgreSQL
echo POSTGRES_DB=acma_production
echo POSTGRES_USER=postgres
echo POSTGRES_PASSWORD=Acma2024!Secure
echo.
echo # Configuración para Rails
echo DATABASE_URL=postgresql://postgres:Acma2024!Secure@db:5432/acma_production
echo RAILS_ENV=production
echo RAILS_MASTER_KEY=your_master_key_here
echo.
echo # Configuración de red
echo # Cambiar esta IP por la IP real del servidor
echo RAILS_HOST=192.168.68.69
echo RAILS_PORT=3000
) > .env

echo [OK] Configuracion restaurada a valores por defecto
goto :continuar

:opcion_invalida
echo [ERROR] Opcion invalida
goto :continuar

:continuar
echo.
set /p otra="¿Desea cambiar otra configuracion? (s/N): "
if /i "%otra%"=="s" goto :configurar
goto :verificar

:verificar
echo.
echo ===============================================
echo           VERIFICANDO CONFIGURACION
echo ===============================================
echo.

:: Verificar que la IP sea válida (formato básico)
for /f "tokens=2 delims==" %%a in ('findstr "RAILS_HOST" .env') do set ip_servidor=%%a
echo IP del servidor: %ip_servidor%

:: Verificar puerto
for /f "tokens=2 delims==" %%a in ('findstr "RAILS_PORT" .env') do set puerto_servidor=%%a
echo Puerto del servidor: %puerto_servidor%

:: Verificar base de datos
for /f "tokens=2 delims==" %%a in ('findstr "POSTGRES_DB" .env') do set nombre_db=%%a
echo Base de datos: %nombre_db%

echo.
echo URL completa del servidor: http://%ip_servidor%:%puerto_servidor%
echo.

echo ===============================================
echo.
echo [OK] Configuracion verificada
echo.
echo SIGUIENTES PASOS:
echo 1. Ejecutar start-server.bat para iniciar el servidor
echo 2. Verificar acceso desde: http://%ip_servidor%:%puerto_servidor%
echo 3. Configurar las aplicaciones cliente con esta URL
echo.
echo ===============================================
echo.
pause
