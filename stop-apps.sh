#!/bin/bash

echo "🛑 Apagando aplicaciones ACMA..."

# Apagar Rails
if flyctl scale count 0 -a acma-rails -y; then
    echo "✅ Rails apagado"
else
    echo "❌ Error al apagar Rails"
fi

# Apagar Optimizer  
if flyctl scale count 0 -a acma-optimizer -y; then
    echo "✅ Optimizer apagado"
else
    echo "❌ Error al apagar Optimizer"
fi

echo "🔌 Aplicaciones apagadas. Consumo: $0"
echo "💡 Para volver a iniciarlas: ./start-apps.sh"
