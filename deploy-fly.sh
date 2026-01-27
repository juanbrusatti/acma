#!/bin/bash

echo "🚀 Desplegando ACMA a Fly.io"

# Verificar si flyctl está instalado
if ! command -v flyctl &> /dev/null; then
    echo "❌ flyctl no está instalado. Instálalo con:"
    echo "curl -L https://fly.io/install.sh | sh"
    exit 1
fi

# Verificar si está logueado
if ! flyctl auth whoami &> /dev/null; then
    echo "❌ No estás logueado en Fly.io. Ejecuta:"
    echo "flyctl auth login"
    exit 1
fi

echo "✅ Verificaciones completadas"

# Desplegar aplicación Rails
echo "📦 Desplegando aplicación Rails..."
cd docker/Aberturas
flyctl deploy

# Desplegar optimizer
echo "🤖 Desplegando optimizer..."
cd docker/optimizer
flyctl deploy

echo "✅ Despliegue completado!"
echo ""
echo "🌐 URLs de las aplicaciones:"
echo "Rails: https://acma-rails.fly.dev"
echo "Optimizer: https://acma-optimizer.fly.dev"
