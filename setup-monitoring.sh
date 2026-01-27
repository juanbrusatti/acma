#!/bin/bash

# Configurar monitoreo automático cada 6 horas
echo "⏰ Configurando monitoreo automático..."

# Agregar al crontab
(crontab -l 2>/dev/null; echo "0 */6 * * * /Users/juan/Desktop/acma/monitor-cost.sh >> /Users/juan/Desktop/acma/monitor.log 2>&1") | crontab -

echo "✅ Monitoreo configurado para ejecutarse cada 6 horas"
echo "📋 Ver logs en: /Users/juan/Desktop/acma/monitor.log"
echo "🔧 Editar con: crontab -e"
