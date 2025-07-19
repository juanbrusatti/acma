#!/bin/bash
set -e

# Si no existe la base de datos, crearla
if [ ! -f db/development.sqlite3 ]; then
  echo "📦 Creando base de datos..."
  bundle exec rails db:setup
fi

exec "$@"
