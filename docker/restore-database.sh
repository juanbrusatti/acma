#!/bin/bash

# ========================================================================
# SCRIPT DE RESTAURACIÓN DE BASE DE DATOS ACMA
# ========================================================================
# Restaura backups de la base de datos PostgreSQL

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
echo "      RESTAURAR BASE DE DATOS ACMA"
echo "==============================================="
echo ""

# Verificar que estamos en el directorio correcto
if [ ! -f "docker-compose.yml" ]; then
    print_error "No se encontró docker-compose.yml"
    print_info "Ejecute este script desde el directorio 'docker'"
    exit 1
fi

# Verificar que existe la carpeta de backups
if [ ! -d "backups" ]; then
    print_error "No se encontró la carpeta de backups"
    print_info "No hay backups disponibles para restaurar"
    exit 1
fi

echo "Backups disponibles:"
echo ""
ls -1 backups/ | grep "backup_acma_" || {
    print_error "No se encontraron backups"
    exit 1
}

echo ""
echo "TIPOS DE RESTAURACIÓN:"
echo ""
echo "1) Restaurar desde SQL dump (recomendado)"
echo "2) Restaurar archivos completos de PostgreSQL"
echo "3) Listar detalles de backups disponibles"
echo ""
read -p "Seleccione el tipo de restauración (1-3): " tipo

case $tipo in
    1)
        # Restaurar desde SQL dump
        echo ""
        echo "RESTAURACIÓN DESDE SQL DUMP"
        echo ""
        print_warning "ATENCIÓN: Esto sobreescribirá todos los datos actuales"
        echo ""
        read -p "¿Está seguro? (s/N): " confirmar

        if [ "$confirmar" != "s" ] && [ "$confirmar" != "S" ]; then
            print_info "Operación cancelada"
            exit 0
        fi

        echo ""
        echo "Archivos SQL disponibles:"
        ls -1 backups/*.sql 2>/dev/null | sed 's/backups\///' || {
            print_error "No se encontraron archivos SQL"
            exit 1
        }
        echo ""
        read -p "Ingrese el nombre del archivo SQL (con .sql): " archivo

        if [ ! -f "backups/$archivo" ]; then
            print_error "Archivo no encontrado: backups/$archivo"
            exit 1
        fi

        echo ""
        print_info "Restaurando desde: $archivo"
        echo ""

        # Verificar que la base de datos esté corriendo
        if ! docker compose ps | grep "db" | grep -q "Up"; then
            print_info "Iniciando base de datos..."
            docker compose up -d db
            sleep 10
        fi

        # Borrar datos actuales y restaurar
        print_info "Borrando datos actuales..."
        docker compose exec db psql -U postgres -d acma_production -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;" >/dev/null 2>&1 || {
            print_warning "No se pudieron borrar los datos existentes (puede ser normal)"
        }

        print_info "Restaurando backup..."
        if docker compose exec -T db psql -U postgres -d acma_production < "backups/$archivo"; then
            print_status "Restauración completada exitosamente"
        else
            print_error "Falló la restauración"
            exit 1
        fi
        ;;

    2)
        # Restaurar archivos completos
        echo ""
        echo "RESTAURACIÓN DE ARCHIVOS COMPLETOS"
        echo ""
        print_warning "ATENCIÓN: Esto reemplazará completamente la base de datos"
        print_warning "Se perderán TODOS los datos actuales"
        echo ""
        read -p "¿Está COMPLETAMENTE seguro? (s/N): " confirmar

        if [ "$confirmar" != "s" ] && [ "$confirmar" != "S" ]; then
            print_info "Operación cancelada"
            exit 0
        fi

        echo ""
        echo "Carpetas de datos disponibles:"
        ls -1d backups/*_data 2>/dev/null | sed 's/backups\///' || {
            print_error "No se encontraron carpetas de datos"
            exit 1
        }
        echo ""
        read -p "Ingrese el nombre de la carpeta (con _data): " carpeta

        if [ ! -d "backups/$carpeta" ]; then
            print_error "Carpeta no encontrada: backups/$carpeta"
            exit 1
        fi

        echo ""
        print_info "Parando servicios..."
        docker compose down

        print_info "Respaldando datos actuales..."
        if [ -d "postgres_data_old" ]; then
            rm -rf "postgres_data_old"
        fi
        if [ -d "postgres_data" ]; then
            mv "postgres_data" "postgres_data_old"
        fi

        print_info "Restaurando archivos..."
        cp -r "backups/$carpeta" "postgres_data"

        print_info "Iniciando servicios..."
        docker compose up -d

        print_status "Restauración de archivos completada"
        print_info "Los datos anteriores están en: postgres_data_old"
        ;;

    3)
        # Listar detalles
        echo ""
        echo "==============================================="
        echo "       DETALLES DE BACKUPS DISPONIBLES"
        echo "==============================================="
        echo ""

        for backup in backups/backup_acma_*; do
            if [ -e "$backup" ]; then
                echo "Backup: $(basename $backup)"
                echo "  Fecha de creación: $(stat -c %y "$backup" 2>/dev/null || stat -f %Sm "$backup" 2>/dev/null || echo "No disponible")"
                echo "  Tamaño: $(du -h "$backup" 2>/dev/null | cut -f1 || echo "No disponible")"

                if [ -f "${backup}.sql" ]; then
                    echo "  Tipo: SQL dump"
                elif [ -d "${backup}_data" ]; then
                    echo "  Tipo: Archivos completos"
                elif [ -f "${backup}.tar.gz" ]; then
                    echo "  Tipo: Comprimido TAR.GZ"
                fi
                echo ""
            fi
        done
        ;;

    *)
        print_error "Tipo de restauración inválido"
        exit 1
        ;;
esac

echo ""
print_info "Operación completada"
