#!/bin/bash
# Script para ver el resumen de los casos de test grandes

echo "======================================================================"
echo "📊 RESUMEN DE CASOS GRANDES - Última Ejecución"
echo "======================================================================"
echo ""

# Colores
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función para mostrar resumen de un caso
show_case_summary() {
    local pattern="$1"
    local case_name="$2"
    
    # Buscar el archivo más reciente
    latest=$(ls -t test_outputs/${pattern}_*/RESUMEN.txt 2>/dev/null | head -1)
    
    if [ -z "$latest" ]; then
        echo -e "${RED}❌ No encontrado: ${case_name}${NC}"
        return
    fi
    
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}📦 ${case_name}${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    # Extraer estadísticas clave
    piezas_cortadas=$(grep "Piezas cortadas:" "$latest" | awk '{print $NF}')
    piezas_sin_colocar=$(grep "Piezas sin colocar:" "$latest" | awk '{print $NF}')
    planchas_usadas=$(grep "Planchas usadas:" "$latest" | awk '{print $NF}')
    sobrantes_utiles=$(grep "Sobrantes útiles:" "$latest" | awk '{print $NF}')
    sobrantes_inutiles=$(grep "Sobrantes inútiles:" "$latest" | awk '{print $NF}')
    
    # Calcular eficiencia
    if [ -n "$piezas_cortadas" ] && [ -n "$piezas_sin_colocar" ]; then
        total=$((piezas_cortadas + piezas_sin_colocar))
        if [ $total -gt 0 ]; then
            eficiencia=$((piezas_cortadas * 100 / total))
        else
            eficiencia=0
        fi
    else
        eficiencia=0
    fi
    
    # Mostrar con colores
    if [ "$piezas_sin_colocar" = "0" ]; then
        echo -e "  ${GREEN}✅ Piezas colocadas: ${piezas_cortadas}/${total} (100%)${NC}"
    else
        echo -e "  ${RED}❌ Piezas colocadas: ${piezas_cortadas}/${total} (${eficiencia}%)${NC}"
        echo -e "  ${RED}   → Sin colocar: ${piezas_sin_colocar}${NC}"
    fi
    
    echo -e "  📊 Planchas usadas: ${planchas_usadas}"
    echo -e "  ♻️  Sobrantes útiles: ${sobrantes_utiles}"
    
    if [ "$sobrantes_inutiles" -gt "10" ]; then
        echo -e "  ${YELLOW}⚠️  Sobrantes inútiles: ${sobrantes_inutiles}${NC}"
    else
        echo -e "  🗑️  Sobrantes inútiles: ${sobrantes_inutiles}"
    fi
    
    # Buscar el ZIP correspondiente
    zip_file=$(ls -t test_outputs/${pattern}_*.zip 2>/dev/null | head -1)
    if [ -n "$zip_file" ]; then
        zip_size=$(du -h "$zip_file" | cut -f1)
        echo -e "  📦 Archivo: $(basename "$zip_file") (${zip_size})"
    fi
    
    echo ""
}

# Mostrar resumen de cada caso grande
show_case_summary "Producción_Alta" "Caso 11: Producción Alta (100 piezas, 20 sobrantes)"
show_case_summary "Multi-tipo" "Caso 12: Multi-tipo (80 piezas, 4 tipos de vidrio)"
show_case_summary "Pedido_Real" "Caso 13: Ventanas Estándar (120 piezas, 25 sobrantes)"
show_case_summary "Stock_Masivo" "Caso 14: Stock Masivo (60 piezas, 40 sobrantes)"
show_case_summary "Optimización_Extrema" "Caso 15: Optimización Extrema (150 piezas, 30 sobrantes)"

echo "======================================================================"
echo ""
echo "💡 Tips:"
echo "  • Ver un caso específico: cat test_outputs/Producción_Alta_*/RESUMEN.txt"
echo "  • Ver PDFs: ls test_outputs/Producción_Alta_*/pdfs/*/*.pdf"
echo "  • Extraer ZIP: unzip test_outputs/Producción_Alta_*.zip"
echo "  • Re-ejecutar todos: make test-cases"
echo ""
echo "======================================================================"
