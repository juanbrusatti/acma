@echo off
title Iniciador del Servidor de la App
cls

echo.
echo ===============================================
echo      INICIADOR Y VERIFICADOR DEL SERVIDOR
echo ===============================================
echo.
echo Verificando dependencias...
echo.

:: 1. Verificar si Docker Desktop esta corriendo
docker --version >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] Docker no esta instalado o no se esta ejecutando.
    echo         Por favor, inicia Docker Desktop y vuelve a intentarlo.
    echo.
    pause
    exit
)
echo [OK] Docker detectado.

:: 2. Verificar si Docker Compose (el nuevo comando) funciona
docker compose version >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] El comando 'docker compose' no funciona.
    echo         Asegurate de que tu version de Docker Desktop este actualizada.
    echo.
    pause
    exit
)
echo [OK] Docker Compose detectado.
echo.
echo Todas las dependencias estan correctas.
echo.
echo Iniciando los servicios en segundo plano...
echo.

:: 3. Iniciar los contenedores
docker compose up -d

echo.
echo ===============================================
echo      Servidor iniciado con exito.
echo      Esta ventana se puede cerrar.
echo ===============================================
echo.
timeout /t 10