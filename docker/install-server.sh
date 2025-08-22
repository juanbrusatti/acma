#!/bin/bash

# ========================================================================
# SCRIPT DE INSTALACIÓN AUTOMÁTICA - SERVIDOR ACMA CON POSTGRESQL
# ========================================================================
# Este script automatiza la instalación del servidor ACMA en la PC cliente
# Ejecutar como administrador en Linux/Mac o en PowerShell como admin en Windows

set -e

echo "🚀 Iniciando instalación del Servidor ACMA con PostgreSQL..."
echo "=================================================================="

# Variables de configuración
INSTALL_DIR="/opt/acma"
SERVICE_NAME="acma-server"
DOCKER_COMPOSE_VERSION="v2.20.0"

# Función para verificar si un comando existe
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Función para instalar Docker en Ubuntu/Debian
install_docker_ubuntu() {
    echo "📦 Instalando Docker en Ubuntu/Debian..."

    # Actualizar paquetes
    sudo apt-get update

    # Instalar dependencias
    sudo apt-get install -y \
        ca-certificates \
        curl \
        gnupg \
        lsb-release

    # Agregar clave GPG de Docker
    sudo mkdir -m 0755 -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

    # Agregar repositorio
    echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
        $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    # Instalar Docker
    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    # Agregar usuario al grupo docker
    sudo usermod -aG docker $USER

    echo "✅ Docker instalado correctamente"
}

# Verificar sistema operativo
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    echo "🔍 Sistema detectado: Linux"

    # Verificar Docker
    if ! command_exists docker; then
        echo "⚠️  Docker no encontrado. Instalando..."

        if command_exists apt-get; then
            install_docker_ubuntu
        else
            echo "❌ Sistema no soportado automáticamente. Instale Docker manualmente."
            exit 1
        fi
    else
        echo "✅ Docker ya está instalado"
    fi

elif [[ "$OSTYPE" == "darwin"* ]]; then
    echo "🔍 Sistema detectado: macOS"
    echo "⚠️  Instale Docker Desktop desde https://docs.docker.com/desktop/mac/install/"

elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
    echo "🔍 Sistema detectado: Windows"
    echo "⚠️  Instale Docker Desktop desde https://docs.docker.com/desktop/windows/install/"
fi

# Verificar que Docker esté corriendo
echo "🔍 Verificando que Docker esté corriendo..."
if ! docker info >/dev/null 2>&1; then
    echo "❌ Docker no está corriendo. Inicie Docker y vuelva a ejecutar este script."
    exit 1
fi

echo "✅ Docker está corriendo correctamente"
echo ""
echo "📋 Configuración del servidor:"
echo "   - Carpeta de instalación: $INSTALL_DIR"
echo "   - Datos de PostgreSQL: $INSTALL_DIR/postgres_data"
echo "   - Puerto de la aplicación: 3000"
echo "   - IP predeterminada: 192.168.68.69"
echo ""

read -p "¿Continuar con la instalación? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Instalación cancelada"
    exit 1
fi

# Crear directorio de instalación
echo "📁 Creando directorio de instalación..."
sudo mkdir -p "$INSTALL_DIR"
sudo chown $USER:$USER "$INSTALL_DIR"

echo "✅ Instalación completada!"
echo ""
echo "📋 PRÓXIMOS PASOS:"
echo "1. Copie los archivos del proyecto a: $INSTALL_DIR"
echo "2. Configure la IP del servidor en el archivo .env"
echo "3. Ejecute: cd $INSTALL_DIR/docker && ./start-server.sh"
echo ""
echo "📖 Para más información, consulte README-SERVIDOR-COMPLETO.md"
