#!/bin/bash

echo "🛑 Deteniendo aplicaciones ACMA..."

# Detener Rails
flyctl scale count 0 -a acma-rails
echo "✅ Rails detenido"

# Detener Optimizer  
flyctl scale count 0 -a acma-optimizer
echo "✅ Optimizer detenido"

echo "🎉 Todas las aplicaciones detenidas. Consumo mínimo."
