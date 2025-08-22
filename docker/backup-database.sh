#!/bin/bash

# ========================================================================
# SCRIPT DE BACKUP DE BASE DE DATOS ACMA - PostgreSQL
# ========================================================================
# Crea backups de la base de datos PostgreSQL con diferentes opciones

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Funciones para output con colores
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

echo ""
echo "==============================================="
echo "       BACKUP DE BASE DE DATOS ACMA"
echo "==============================================="
echo ""

# Verificar que estamos en el directorio correcto
if [ ! -f "docker-compose.yml" ]; then
    print_error "No se encontró docker-compose.yml"
    print_info "Ejecute este script desde el directorio 'docker'"
    exit 1
fi

# Verificar que Docker está corriendo
if ! docker info >/dev/null 2>&1; then
    print_error "Docker no está corriendo."
    print_info "Inicie Docker e intente nuevamente."
    exit 1
fi

# Crear timestamp para el backup
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_NAME="backup_acma_${TIMESTAMP}"

# Crear carpeta de backups si no existe
if [ ! -d "backups" ]; then
    print_info "Creando carpeta de backups..."
    mkdir -p backups
fi

print_info "Creando backup: $BACKUP_NAME"
print_info "Timestamp: $TIMESTAMP"
echo ""

# Mostrar opciones de backup
echo "Tipos de backup disponibles:"
echo ""
echo "1) Backup completo (SQL dump + archivos de datos)"
echo "2) Solo SQL dump (más rápido, solo datos)"
echo "3) Solo copia de archivos (incluye configuraciones)"
echo "4) Backup automático comprimido (recomendado)"
echo ""
read -p "Seleccione el tipo de backup (1-4): " tipo

case $tipo in
    1)
        # Backup completo
        echo ""
        print_info "Realizando backup completo..."
        echo ""

        # 1. SQL Dump
        print_info "Paso 1/3: Creando SQL dump..."
        if docker compose exec -T db pg_dump -U postgres -h localhost acma_production > "backups/${BACKUP_NAME}.sql"; then
            print_status "SQL dump creado: ${BACKUP_NAME}.sql"
        else
            print_error "Falló al crear SQL dump"
            exit 1
        fi

        # 2. Copia de archivos de datos
        print_info "Paso 2/3: Copiando archivos de PostgreSQL..."
        if [ -d "backups/${BACKUP_NAME}_data" ]; then
            rm -rf "backups/${BACKUP_NAME}_data"
        fi

        if cp -r postgres_data "backups/${BACKUP_NAME}_data"; then
            print_status "Archivos de datos copiados"
        else
            print_error "Falló al copiar archivos de datos"
            exit 1
        fi

        # 3. Copia de configuraciones
        print_info "Paso 3/3: Copiando configuraciones..."
        cp .env "backups/${BACKUP_NAME}_config.env" 2>/dev/null || touch "backups/${BACKUP_NAME}_config.env"
        cp docker-compose.yml "backups/${BACKUP_NAME}_docker-compose.yml"
        print_status "Configuraciones copiadas"
        ;;

    2)
        # Solo SQL dump
        echo ""
        print_info "Realizando backup SQL..."
        echo ""
        if docker compose exec -T db pg_dump -U postgres -h localhost acma_production > "backups/${BACKUP_NAME}.sql"; then
            print_status "SQL dump creado: ${BACKUP_NAME}.sql"
        else
            print_error "Falló al crear SQL dump"
            exit 1
        fi
        ;;

    3)
        # Solo archivos
        echo ""
        print_info "Copiando archivos de datos..."
        echo ""
        if [ -d "backups/${BACKUP_NAME}_data" ]; then
            rm -rf "backups/${BACKUP_NAME}_data"
        fi

        if cp -r postgres_data "backups/${BACKUP_NAME}_data"; then
            print_status "Archivos copiados a: ${BACKUP_NAME}_data/"
        else
            print_error "Falló al copiar archivos"
            exit 1
        fi
        ;;

    4)
        # Backup automático comprimido
        echo ""
        print_info "Realizando backup automático comprimido..."
        echo ""

        # SQL Dump
        print_info "Creando SQL dump..."
        if docker compose exec -T db pg_dump -U postgres -h localhost acma_production > "backups/${BACKUP_NAME}.sql"; then
            print_status "SQL dump creado"
        else
            print_error "Falló al crear SQL dump"
            exit 1
        fi

        # Comprimir todo
        print_info "Comprimiendo backup..."
        if command -v tar >/dev/null 2>&1; then
            # Usar tar con gzip
            tar -czf "backups/${BACKUP_NAME}.tar.gz" \
                -C backups "${BACKUP_NAME}.sql" \
                -C .. .env docker-compose.yml 2>/dev/null || \
            tar -czf "backups/${BACKUP_NAME}.tar.gz" \
                -C backups "${BACKUP_NAME}.sql" \
                -C .. docker-compose.yml

            # Limpiar archivo SQL temporal
            rm "backups/${BACKUP_NAME}.sql"
            print_status "Backup comprimido creado: ${BACKUP_NAME}.tar.gz"
        else
            print_warning "tar no disponible, manteniendo archivo SQL sin comprimir"
        fi
        ;;

    *)
        print_error "Tipo de backup inválido"
        exit 1
        ;;
esac

# Mostrar resultado
echo ""
print_status "==============================================="
print_status "         BACKUP COMPLETADO EXITOSAMENTE"
print_status "==============================================="
echo ""
echo "Detalles del backup:"
echo "- Nombre: $BACKUP_NAME"
echo "- Fecha: $(date '+%d/%m/%Y %H:%M:%S')"
echo "- Ubicación: $(pwd)/backups/"
echo ""

# Mostrar archivos creados
echo "Archivos creados:"
ls -la backups/ | grep "$BACKUP_NAME" || echo "No se encontraron archivos (error)"
echo ""

# Mostrar información de la base de datos
echo "Información de la base de datos:"
docker compose exec db psql -U postgres -d acma_production -c "SELECT pg_size_pretty(pg_database_size('acma_production')) as database_size;" 2>/dev/null || echo "No se pudo obtener el tamaño"
echo ""

echo "==============================================="
echo ""
echo "INSTRUCCIONES DE RESTAURACIÓN:"
echo ""
echo "Para SQL dump:"
echo "  docker compose exec -T db psql -U postgres -d acma_production < backups/${BACKUP_NAME}.sql"
echo ""
echo "Para archivos completos:"
echo "  1. docker compose down"
echo "  2. rm -rf postgres_data"
echo "  3. cp -r backups/${BACKUP_NAME}_data postgres_data"
echo "  4. docker compose up -d"
echo ""
echo "Para backup comprimido:"
echo "  1. tar -xzf backups/${BACKUP_NAME}.tar.gz -C backups/"
echo "  2. Seguir instrucciones de SQL dump"
echo ""

# Mostrar estadísticas de backups
echo "Estadísticas de backups:"
backup_count=$(ls -1 backups/ | wc -l)
echo "- Total de backups: $backup_count"

if [ $backup_count -gt 10 ]; then
    print_warning "Tienes más de 10 backups. Considera limpiar los antiguos."
    echo "Para limpiar backups antiguos:"
    echo "  find backups/ -name 'backup_acma_*' -mtime +30 -delete"
fi

echo ""
print_info "¡Backup completado exitosamente!"
