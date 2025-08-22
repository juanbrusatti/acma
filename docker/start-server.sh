#!/bin/bash

# ========================================================================
# SCRIPT DE INICIO DEL SERVIDOR ACMA - VERSIÓN LINUX/MAC
# ========================================================================
# Equivalente a start-server.bat pero para sistemas Unix

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo ""
echo "=============================================="
echo "     INICIADOR Y VERIFICADOR DEL SERVIDOR"
echo "=============================================="
echo ""

# Función para imprimir mensajes con color
print_status() {
    echo -e "${GREEN}[OK]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[AVISO]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

echo "Verificando dependencias..."
echo ""

# 1. Verificar si Docker está instalado y corriendo
if ! command -v docker >/dev/null 2>&1; then
    print_error "Docker no está instalado."
    print_info "Por favor, instale Docker y vuelva a intentarlo."
    print_info "https://docs.docker.com/get-docker/"
    echo ""
    exit 1
fi
print_status "Docker detectado."

# 2. Verificar si Docker está corriendo
if ! docker info >/dev/null 2>&1; then
    print_error "Docker no se está ejecutando."
    print_info "Por favor, inicie Docker y vuelva a intentarlo."
    echo ""
    exit 1
fi
print_status "Docker está corriendo."

# 3. Verificar si Docker Compose está disponible
if ! docker compose version >/dev/null 2>&1; then
    print_error "El comando 'docker compose' no funciona."
    print_info "Asegúrese de que su versión de Docker esté actualizada."
    echo ""
    exit 1
fi
print_status "Docker Compose detectado."

# 4. Verificar que estamos en el directorio correcto
if [ ! -f "docker-compose.yml" ]; then
    print_error "No se encontró docker-compose.yml en el directorio actual."
    print_info "Ejecute este script desde el directorio 'docker' del proyecto."
    echo ""
    exit 1
fi
print_status "Archivo docker-compose.yml encontrado."

# 5. Verificar configuración
if [ ! -f ".env" ]; then
    print_warning "No se encontró archivo .env. Usando configuración por defecto."
else
    print_status "Archivo .env encontrado."
fi

echo ""
print_info "Todas las dependencias están correctas."
echo ""

# Verificar si hay contenedores corriendo
if docker compose ps | grep -q "Up"; then
    print_warning "Hay contenedores ya corriendo. ¿Desea reiniciarlos?"
    echo ""
    echo "Opciones:"
    echo "1) Reiniciar completamente (recomendado)"
    echo "2) Solo verificar estado"
    echo "3) Cancelar"
    echo ""
    read -p "Seleccione una opción (1-3): " choice

    case $choice in
        1)
            print_info "Reiniciando servicios..."
            docker compose down
            ;;
        2)
            print_info "Estado actual de los servicios:"
            docker compose ps
            exit 0
            ;;
        3)
            print_info "Operación cancelada"
            exit 0
            ;;
        *)
            print_warning "Opción inválida. Continuando con reinicio..."
            docker compose down
            ;;
    esac
fi

echo ""
print_info "Iniciando los servicios en segundo plano..."
echo ""

# Iniciar los contenedores
if docker compose up -d; then
    echo ""
    print_status "=============================================="
    print_status "     Servidor iniciado con éxito."
    print_status "=============================================="
    echo ""

    # Mostrar información útil
    print_info "Información del servidor:"
    echo "  📍 URL local: http://localhost:3000"
    echo "  🌐 URL de red: http://$(hostname -I | awk '{print $1}'):3000"
    echo "  🐘 PostgreSQL: localhost:5432"
    echo "  📁 Datos persistentes: ./postgres_data/"
    echo ""

    print_info "Comandos útiles:"
    echo "  Ver logs:          docker compose logs -f"
    echo "  Parar servicios:   docker compose down"
    echo "  Estado:            docker compose ps"
    echo "  Reiniciar:         docker compose restart"
    echo ""

    # Esperar un poco y verificar estado
    sleep 5
    print_info "Verificando estado de los servicios..."
    docker compose ps

else
    print_error "Error al iniciar los servicios"
    print_info "Verificando logs de error..."
    docker compose logs
    exit 1
fi
