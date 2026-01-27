#!/bin/bash
echo " Iniciando ACMA..."
cd docker
docker compose --profile development up -d
echo "✅ ACMA iniciado!"
echo "🌐 Aplicación: http://localhost:3000"
echo "🤖 Optimizer: http://localhost:8000"
docker compose ps