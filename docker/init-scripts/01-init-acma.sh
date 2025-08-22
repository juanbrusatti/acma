#!/bin/bash
set -e

# Script de inicialización de PostgreSQL
# Se ejecuta automáticamente la primera vez que se crea el contenedor

echo "🔧 Configurando PostgreSQL para ACMA..."

# Crear bases de datos adicionales si es necesario
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    -- Configurar PostgreSQL para mejor rendimiento
    ALTER SYSTEM SET shared_preload_libraries = 'pg_stat_statements';
    ALTER SYSTEM SET max_connections = 100;
    ALTER SYSTEM SET shared_buffers = '256MB';
    ALTER SYSTEM SET effective_cache_size = '1GB';
    ALTER SYSTEM SET work_mem = '4MB';

    -- Crear extensiones útiles
    CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
    CREATE EXTENSION IF NOT EXISTS pgcrypto;

    GRANT ALL PRIVILEGES ON DATABASE $POSTGRES_DB TO $POSTGRES_USER;
EOSQL

echo "✅ PostgreSQL configurado correctamente para ACMA"
