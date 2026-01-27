#!/bin/bash

echo "▶️ Iniciando aplicaciones ACMA..."

# Despertar Rails (hace una request para que auto_start lo inicie)
echo "⏳ Despertando Rails..."
if curl -s --max-time 60 -o /dev/null -w "%{http_code}" https://acma-rails.fly.dev/up | grep -q "200"; then
    echo "✅ Rails iniciado"
else
    echo "⚠️ Rails tardando en despertar (puede tomar unos segundos más)"
fi

# Despertar Optimizer
echo "⏳ Despertando Optimizer..."
if curl -s --max-time 60 -o /dev/null -w "%{http_code}" https://acma-optimizer.fly.dev/health | grep -q "200"; then
    echo "✅ Optimizer iniciado"
else
    echo "⚠️ Optimizer tardando en despertar (puede tomar unos segundos más)"
fi

echo "🎉 Aplicaciones listas para usar."
echo "🌐 Rails: https://acma-rails.fly.dev"
echo "🤖 Optimizer: https://acma-optimizer.fly.dev"
