#!/bin/bash
set -e

APP_ROOT="/app"
SETUP_DONE_FILE="/app/tmp/db_setup_done"

mkdir -p /app/tmp

echo "🔍 Directorio de trabajo actual: $(pwd)"
echo "🔍 Verificando archivo indicador: ${SETUP_DONE_FILE}"

# Función para esperar a PostgreSQL
wait_for_postgres() {
  echo "⏳ Esperando a PostgreSQL..."
  until pg_isready -h db -p 5432 -U ${POSTGRES_USER:-postgres}; do
    echo "⏳ PostgreSQL no está listo - esperando..."
    sleep 2
  done
  echo "✅ PostgreSQL está disponible!"
}

wait_for_postgres

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

exec "$@"
