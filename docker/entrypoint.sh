#!/bin/bash
set -e

# Determinar la ruta de la aplicación
APP_ROOT="/app"
SETUP_DONE_FILE="/app/tmp/db_setup_done"

# Crear directorio tmp si no existe
mkdir -p /app/tmp

echo "🔍 Directorio de trabajo actual: $(pwd)"
echo "🔍 Verificando si existe el archivo indicador: ${SETUP_DONE_FILE}"

# Función para esperar a que PostgreSQL esté disponible
wait_for_postgres() {
  echo "⏳ Esperando a que PostgreSQL esté disponible..."
  until pg_isready -h db -p 5432 -U postgres; do
    echo "⏳ PostgreSQL no está listo - esperando..."
    sleep 2
  done
  echo "✅ PostgreSQL está disponible!"
}

# Esperar a que PostgreSQL esté disponible
wait_for_postgres

# Usar un archivo indicador para saber si ya se ha configurado la BD
if [ -f "$SETUP_DONE_FILE" ]; then
  echo "📦 El archivo indicador existe - saltando configuración inicial"
else
  echo "📦 No se encontró archivo indicador - realizando configuración inicial"

  # Verificar si ya existe la BD
  if bundle exec rails runner "ActiveRecord::Base.connection" 2>/dev/null; then
    echo "📦 Base de datos existente encontrada, usando base de datos actual"

    # Correr migraciones pendientes sin recrear la BD
    echo "📦 Ejecutando migraciones pendientes..."
    bundle exec rails db:migrate
  else
    echo "📦 No se encontró base de datos, creando desde cero..."
    bundle exec rails db:setup
  fi

  # Crear el archivo indicador para futuras ejecuciones
  touch "$SETUP_DONE_FILE"
  echo "📦 Archivo indicador creado para futuras ejecuciones"
fi

exec "$@"
