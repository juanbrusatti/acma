#!/bin/bash
echo "🛑 Deteniendo ACMA..."
cd /Users/juan/Desktop/acma/docker
docker compose down --remove-orphans
echo "✅ ACMA detenido!"