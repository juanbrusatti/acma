#!/bin/bash
echo "🛑 Deteniendo ACMA..."
cd docker
docker compose down --remove-orphans
echo "✅ ACMA detenido!"