#!/bin/bash

# Script para migrar datos de SQLite a PostgreSQL
# Ejecutar este script después de tener PostgreSQL funcionando

echo "🔄 Iniciando migración de SQLite a PostgreSQL..."

# Verificar que existe la base de datos SQLite
if [ ! -f "./Aberturas/storage/development.sqlite3" ]; then
    echo "❌ No se encontró la base de datos SQLite en ./Aberturas/storage/development.sqlite3"
    echo "ℹ️  Si es una instalación nueva, no es necesario ejecutar este script."
    exit 1
fi

echo "📦 Base de datos SQLite encontrada"

# Instalar pgloader si no está disponible
if ! command -v pgloader &> /dev/null; then
    echo "📦 Instalando pgloader..."
    sudo apt-get update
    sudo apt-get install -y pgloader
fi

# Crear archivo de configuración para pgloader
cat > migrate_config.load << EOF
LOAD DATABASE
     FROM sqlite:///$(pwd)/Aberturas/storage/development.sqlite3
     INTO postgresql://postgres:password@localhost:5432/acma_development

WITH include drop, create tables, create indexes, reset sequences

SET work_mem to '16MB', maintenance_work_mem to '512 MB';
EOF

echo "🔄 Ejecutando migración con pgloader..."
pgloader migrate_config.load

echo "✅ Migración completada!"
echo "🧹 Limpiando archivos temporales..."
rm migrate_config.load

echo "ℹ️  Recomendación: Hacer backup de la base de datos SQLite antes de eliminarla"
echo "ℹ️  Una vez verificado que todo funciona, puedes eliminar:"
echo "   - ./Aberturas/storage/development.sqlite3"
echo "   - ./Aberturas/storage/test.sqlite3"
