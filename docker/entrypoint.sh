#!/bin/bash
set -e

rm -f /app/tmp/pids/server.pid

exec "$@"

APP_ROOT="/app"
SETUP_DONE_FILE="$APP_ROOT/tmp/db_setup_done"

mkdir -p "$APP_ROOT/tmp"

echo "🔍 Directorio de trabajo actual: $(pwd)"
echo "🔍 RAILS_ENV = $RAILS_ENV"
echo "🔍 DATABASE_URL = $DATABASE_URL"

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
