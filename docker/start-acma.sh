#!/bin/bash
echo "🚀 Iniciando ACMA..."
cd /Users/juan/Desktop/acma/docker
POSTGRES_USER=postgres POSTGRES_PASSWORD=Acma2024!Secure DEV_POSTGRES_DB=acma_development RAILS_ENV=development DATABASE_URL=postgresql://postgres:Acma2024!Secure@db:5432/acma_development docker compose --profile development up -d
echo "✅ ACMA iniciado!"
echo "🌐 Aplicación: http://localhost:3000"
echo "🤖 Optimizer: http://localhost:8000"
docker compose ps