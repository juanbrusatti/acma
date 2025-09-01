#!/bin/bash
set -e

APP_ROOT="/app"
SETUP_DONE_FILE="/app/tmp/db_setup_done"

mkdir -p /app/tmp

echo "🔍 Directorio de trabajo actual: $(pwd)"

# Selección de variables según entorno
if [ "$RAILS_ENV" = "production" ]; then
  export POSTGRES_DB=$PROD_POSTGRES_DB
  export DATABASE_HOST=$PROD_DATABASE_HOST
  export DATABASE_PORT=$PROD_DATABASE_PORT
  export DATABASE_URL=$PROD_DATABASE_URL
  export RAILS_HOST=$PROD_RAILS_HOST
  export RAILS_PORT=$PROD_RAILS_PORT
else
  export POSTGRES_DB=$DEV_POSTGRES_DB
  export DATABASE_HOST=$DEV_DATABASE_HOST
  export DATABASE_PORT=$DEV_DATABASE_PORT
  export DATABASE_URL=$DEV_DATABASE_URL
  export RAILS_HOST=$DEV_RAILS_HOST
  export RAILS_PORT=$DEV_RAILS_PORT
fi

echo "🔍 Verificando archivo indicador: ${SETUP_DONE_FILE}"

# Función para esperar a PostgreSQL (solo en desarrollo)
wait_for_postgres() {
  echo "⏳ Esperando a PostgreSQL en ${DATABASE_HOST}:${DATABASE_PORT}..."
  until pg_isready -h "${DATABASE_HOST}" -p "${DATABASE_PORT}" -U "${POSTGRES_USER}"; do
    echo "⏳ PostgreSQL no está listo - esperando..."
    sleep 2
  done
  echo "✅ PostgreSQL está disponible!"
}

if [ "$RAILS_ENV" = "development" ]; then
  wait_for_postgres
fi

# Migraciones / Setup
if [ -f "$SETUP_DONE_FILE" ]; then
  echo "📦 Archivo indicador existe - corriendo migraciones pendientes..."
  bundle exec rails db:migrate
else
  echo "📦 No se encontró archivo indicador - configurando base de datos..."
  if bundle exec rails runner "ActiveRecord::Base.connection" 2>/dev/null; then
    echo "📦 Base de datos ya existe, corriendo migraciones..."
    bundle exec rails db:migrate
  else
    echo "📦 No se encontró base de datos, creando..."
    bundle exec rails db:setup
  fi
  touch "$SETUP_DONE_FILE"
  echo "📦 Archivo indicador creado"
fi

echo "🚀 Iniciando servidor Rails en $RAILS_ENV..."
exec bundle exec rails server -b 0.0.0.0 -p "${RAILS_PORT:-3000}"
