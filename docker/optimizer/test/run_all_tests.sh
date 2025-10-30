#!/bin/bash
# Script para ejecutar los tests del optimizador automáticamente
# Uso: ./run_all_tests.sh

set -e  # Salir si cualquier comando falla

echo "🚀 Ejecutando suite completa de tests del optimizador"
echo "======================================================================"
echo ""

# Colores para output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Cambiar al directorio del optimizador
cd "$(dirname "$0")/.."

echo "📍 Directorio de trabajo: $(pwd)"
echo ""

# Test 1: Tests unitarios
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "1️⃣  Ejecutando tests unitarios (unittest)..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if python test/test_optimizer.py 2>&1 | tee /tmp/test_optimizer.log; then
    echo -e "${GREEN}✅ Tests unitarios: EXITOSO${NC}"
    UNITTEST_PASS=1
else
    echo -e "${RED}❌ Tests unitarios: FALLIDO${NC}"
    UNITTEST_PASS=0
fi
echo ""

# Test 2: Casos predefinidos
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "2️⃣  Ejecutando casos de test predefinidos..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if python test/run_test_cases.py 2>&1 | tee /tmp/test_cases.log; then
    echo -e "${GREEN}✅ Casos predefinidos: EXITOSO${NC}"
    TESTCASE_PASS=1
else
    echo -e "${RED}❌ Casos predefinidos: FALLIDO${NC}"
    TESTCASE_PASS=0
fi
echo ""

# Resumen final
echo "======================================================================"
echo "📊 RESUMEN FINAL"
echo "======================================================================"

if [ $UNITTEST_PASS -eq 1 ]; then
    echo -e "✅ Tests unitarios: ${GREEN}PASS${NC}"
else
    echo -e "❌ Tests unitarios: ${RED}FAIL${NC}"
fi

if [ $TESTCASE_PASS -eq 1 ]; then
    echo -e "✅ Casos predefinidos: ${GREEN}PASS${NC}"
else
    echo -e "❌ Casos predefinidos: ${RED}FAIL${NC}"
fi

echo "======================================================================"

# Exit con código de error si alguno falló
if [ $UNITTEST_PASS -eq 0 ] || [ $TESTCASE_PASS -eq 0 ]; then
    echo -e "${RED}❌ Algunos tests fallaron${NC}"
    exit 1
else
    echo -e "${GREEN}✅ Todos los tests pasaron exitosamente${NC}"
    exit 0
fi
