#!/bin/bash

echo "▶️ Iniciando aplicaciones ACMA..."

# Iniciar Rails
flyctl scale count 1 -a acma-rails
echo "✅ Rails iniciado"

# Iniciar Optimizer
flyctl scale count 1 -a acma-optimizer
echo "✅ Optimizer iniciado"

echo "🎉 Todas las aplicaciones iniciadas. Listas para usar."
