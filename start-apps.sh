#!/bin/bash

echo "▶️ Iniciando aplicaciones ACMA..."

# Iniciar Rails
if flyctl scale count 1 -a acma-rails; then
    echo "✅ Rails iniciado"
else
    echo "❌ Error al iniciar Rails"
    exit 1
fi

# Iniciar Optimizer
if flyctl scale count 1 -a acma-optimizer; then
    echo "✅ Optimizer iniciado"
else
    echo "❌ Error al iniciar Optimizer"
    exit 1
fi

echo "🎉 Todas las aplicaciones iniciadas. Listas para usar."
