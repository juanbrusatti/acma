#!/bin/bash

# Script simplificado para monitorear y detener apps manualmente

LIMIT_USD=5

echo "🔍 Verificando estado de las aplicaciones..."

# Verificar estado de Rails
RAILS_STATUS=$(flyctl status -a acma-rails --json 2>/dev/null | jq -r '.status // "unknown"')
echo "🚊 Rails: $RAILS_STATUS"

# Verificar estado de Optimizer
OPTIMIZER_STATUS=$(flyctl status -a acma-optimizer --json 2>/dev/null | jq -r '.status // "unknown"')
echo "⚙️  Optimizer: $OPTIMIZER_STATUS"

# Opción de detener manualmente si se excede el límite estimado
echo ""
echo "💡 Para controlar el consumo manualmente:"
echo "   � Detener Rails:     flyctl scale count 0 -a acma-rails"
echo "   🛑 Detener Optimizer: flyctl scale count 0 -a acma-optimizer"
echo "   ▶️  Iniciar Rails:     flyctl scale count 1 -a acma-rails"
echo "   ▶️  Iniciar Optimizer: flyctl scale count 1 -a acma-optimizer"
echo ""
echo "📊 Para ver consumo detallado:"
echo "   🔗 Dashboard: https://fly.io/dashboard"
echo "   📧 Configura alerts de \$${LIMIT_USD} USD en Settings → Billing"

# Verificar si las apps están corriendo para estimar consumo
if [[ "$RAILS_STATUS" == "running" ]] && [[ "$OPTIMIZER_STATUS" == "running" ]]; then
    echo "⚠️  Ambas aplicaciones están corriendo. Consumo activo."
elif [[ "$RAILS_STATUS" == "running" ]] || [[ "$OPTIMIZER_STATUS" == "running" ]]; then
    echo "ℹ️  Una aplicación está corriendo. Consumo moderado."
else
    echo "✅ Ambas aplicaciones están detenidas. Consumo mínimo."
fi
