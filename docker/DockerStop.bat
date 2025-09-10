@echo off
echo Cerrando Docker Desktop...
taskkill /IM "Docker Desktop.exe" /F
wsl --shutdown
exit
