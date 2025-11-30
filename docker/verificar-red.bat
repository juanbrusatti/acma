@echo off
echo 🌐 VERIFICADOR DE CONECTIVIDAD DE RED - ACMA
echo ============================================

echo.
echo 📊 Verificando IP del servidor...
ipconfig | findstr "IPv4"

echo.
echo 📊 Verificando puerto 3000...
netstat -an | findstr ":3000"
if errorlevel 1 (
    echo ❌ Puerto 3000: NO está en uso (aplicación NO está corriendo)
    echo 💡 Ejecuta primero: 1-start_server.bat
) else (
    echo ✅ Puerto 3000: EN USO (aplicación está corriendo)
)

echo.
echo 📊 Verificando firewall de Windows...
echo ⚠️  Si no puedes conectarte desde otra PC, puede ser el firewall
echo 🔧 Solución: Permitir la aplicación Rails en el firewall de Windows

echo.
echo 📊 Verificando conectividad desde otra PC...
echo 💡 Desde la otra PC, ejecuta estos comandos para probar:
echo.
echo    ping 192.168.0.150
echo    telnet 192.168.0.150 3000
echo.
echo 🌐 URLs para probar:
echo    Local: http://localhost:3000
echo    Red:   http://192.168.0.150:3000

echo.
echo 📊 Verificando contenedores Docker...
docker compose ps

echo.
echo 🔧 Si aún no funciona:
echo 1. Verifica que el firewall de Windows permita Docker
echo 2. Verifica que Docker Desktop esté configurado para compartir en red
echo 3. Intenta reiniciar Docker Desktop
echo 4. Verifica que la IP 192.168.0.150 sea correcta con 'ipconfig'

echo.
pause
