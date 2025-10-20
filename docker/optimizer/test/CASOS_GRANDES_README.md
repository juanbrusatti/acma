# 📦 Casos de Test Grandes - Documentación

## 🎯 Resumen

Se agregaron **5 casos de test grandes y complejos** que prueban el optimizador con volúmenes realistas de producción:

| # | Nombre del Caso | Piezas | Sobrantes | Planchas | Complejidad |
|---|----------------|--------|-----------|----------|-------------|
| 11 | **Producción Alta** | 100 | 20 | 10 nuevas | ⭐⭐⭐⭐ |
| 12 | **Multi-tipo** | 80 | 15 | 20 nuevas (4 tipos) | ⭐⭐⭐⭐⭐ |
| 13 | **Ventanas Estándar** | 120 | 25 | 20 nuevas | ⭐⭐⭐⭐⭐ |
| 14 | **Stock Masivo** | 60 | 40 | 15 nuevas | ⭐⭐⭐⭐ |
| 15 | **Optimización Extrema** | 150 | 30 | 25 nuevas | ⭐⭐⭐⭐⭐ |

---

## 📊 Caso 11: Producción Alta

**100 piezas variadas con 20 sobrantes**

### Características:
- **Piezas grandes**: 5x (800×1200) + 3x (1000×1000) + 4x (900×1500)
- **Piezas medianas**: 15x (500×600) + 12x (400×700) + 10x (600×500)
- **Piezas pequeñas**: 20x (250×300) + 18x (200×400) + 13x (300×350)

### Stock disponible:
- **4 sobrantes grandes** (1500-1800mm) para piezas grandes
- **6 sobrantes medianos** (1000-1400mm) para piezas medianas
- **10 sobrantes pequeños** (600-950mm) para piezas pequeñas
- **10 planchas nuevas** 2000×2000 FLO 4mm

### Objetivo:
- ✅ Colocar 100 piezas
- ✅ Usar máximo 15 planchas
- ✅ Eficiencia mínima: 65%
- ✅ Priorizar uso de sobrantes

### Resultado Esperado:
El optimizador debe:
1. Usar primero los sobrantes grandes para piezas grandes
2. Agrupar piezas medianas en sobrantes medianos
3. Maximizar piezas pequeñas en sobrantes pequeños
4. Minimizar planchas nuevas necesarias

---

## 🎨 Caso 12: Multi-tipo

**80 piezas con 4 tipos de vidrio diferentes y 15 sobrantes**

### Tipos de vidrio:
1. **FLO 4mm**: 8x (700×900) + 12x (500×600) = 20 piezas
2. **LAM 3+3**: 6x (800×1000) + 15x (400×500) = 21 piezas
3. **FLO 6mm**: 5x (900×1200) + 10x (600×800) = 15 piezas
4. **LAM 4+4**: 4x (1000×1000) + 20x (300×400) = 24 piezas

### Stock por tipo:
- **FLO 4mm**: 4 sobrantes (1000-1600mm) + 5 planchas nuevas
- **LAM 3+3**: 3 sobrantes (1100-1700mm) + 5 planchas nuevas
- **FLO 6mm**: 4 sobrantes (900-1800mm) + 5 planchas nuevas
- **LAM 4+4**: 4 sobrantes (800-1600mm) + 5 planchas nuevas

### Objetivo:
- ✅ Colocar 80 piezas (20+21+15+24)
- ✅ Usar máximo 12 planchas
- ✅ Eficiencia mínima: 60%
- ✅ Respetar separación por tipo de vidrio

### Desafío:
El optimizador debe **manejar 4 grupos independientes** de vidrio, cada uno con su propio stock y optimización.

---

## 🏢 Caso 13: Ventanas Estándar

**Pedido real de obra: 120 piezas de ventanas con 25 sobrantes**

### Distribución realista:
- **30 ventanas 120×150** (más común en obras)
- **25 ventanas 100×120** (mediana popular)
- **20 ventanas 80×100** (pequeña estándar)
- **8 puertas 90×200** (grandes)
- **7 puertas 80×210** (grandes)
- **15 ventanas 60×80** (baño/cocina)
- **15 ventanas 50×60** (ventiluz)

### Stock:
- **25 sobrantes progresivos**: 1800mm a 900mm (simulando stock real acumulado)
- **20 planchas nuevas** 2000×2000 FLO 4mm

### Objetivo:
- ✅ Colocar 120 piezas
- ✅ Usar máximo 30 planchas
- ✅ Eficiencia mínima: 65%
- ✅ Maximizar uso de sobrantes acumulados

### Caso de uso:
Este test simula un **pedido real de una obra** con medidas estándar de abertura argentinas.

---

## 📦 Caso 14: Stock Masivo

**60 piezas con 40 sobrantes disponibles**

### Piezas:
- **60 piezas de tamaños progresivos**: 
  - Pieza 1: 320×415
  - Pieza 2: 340×430
  - Pieza 3: 360×445
  - ...
  - Pieza 60: 1500×1300

### Stock:
- **40 sobrantes de diferentes tamaños**: 
  - Stock 1: 830×925 LAM 3+3
  - Stock 2: 860×950 LAM 3+3
  - ...
  - Stock 40: 2000×1875 LAM 3+3
- **15 planchas nuevas** 2000×2000 LAM 3+3

### Objetivo:
- ✅ Colocar 60 piezas
- ✅ Usar máximo 20 planchas
- ✅ Eficiencia mínima: 55%

### Desafío:
Con **40 sobrantes** disponibles, el optimizador debe:
1. Evaluar eficientemente qué sobrantes usar
2. No desperdiciar tiempo probando todas las combinaciones
3. Seleccionar los mejores sobrantes para cada pieza

---

## 🚀 Caso 15: Optimización Extrema

**150 piezas variadas con 30 sobrantes - Test de stress máximo**

### Distribución de piezas:
- **6 piezas muy grandes**: 1400-1500mm × 1700-1800mm
- **37 piezas grandes**: 800-1000mm × 1000-1200mm
- **60 piezas medianas**: 500-600mm × 650-800mm
- **47 piezas pequeñas**: 250-300mm × 350-400mm

### Stock:
- **10 sobrantes grandes** (1200-1700mm)
- **10 sobrantes medianos** (900-1200mm)
- **10 sobrantes pequeños** (600-800mm)
- **25 planchas nuevas** 2000×2000 FLO 6mm

### Objetivo:
- ✅ Colocar 150 piezas
- ✅ Usar máximo 40 planchas
- ✅ Eficiencia mínima: 60%

### Test de rendimiento:
Este es el **test más exigente**:
- Más piezas (150)
- Más sobrantes (30)
- Mayor variedad de tamaños
- Debe completar en tiempo razonable (< 5 minutos)

---

## 🎯 Ejecutar los Tests

### Todos los tests (incluye los 5 nuevos):
```bash
cd /home/mateo/Dlay/acma/docker/optimizer
make test-cases
```

### Solo casos grandes (filtrado manual):
```bash
# Ver resultados de los casos grandes
ls -la test_outputs/ | grep -E "(Producción|Multi-tipo|Ventanas|Stock|Extrema)"
```

### Ver resultados específicos:
```bash
# Caso 11: Producción Alta
cat "test_outputs/Producción_Alta_"*/RESUMEN.txt

# Caso 12: Multi-tipo
cat "test_outputs/Multi-tipo_"*/RESUMEN.txt

# Caso 13: Ventanas Estándar
cat "test_outputs/Pedido_Real_"*/RESUMEN.txt

# Caso 14: Stock Masivo
cat "test_outputs/Stock_Masivo_"*/RESUMEN.txt

# Caso 15: Optimización Extrema
cat "test_outputs/Optimización_Extrema_"*/RESUMEN.txt
```

---

## 📈 Métricas Esperadas

### Eficiencia por caso:
| Caso | Piezas | Sobrantes | Planchas Max | Eficiencia Min | Tiempo Esperado |
|------|--------|-----------|--------------|----------------|-----------------|
| 11 | 100 | 20 | 15 | 65% | ~30s |
| 12 | 80 | 15 | 12 | 60% | ~45s (4 tipos) |
| 13 | 120 | 25 | 30 | 65% | ~40s |
| 14 | 60 | 40 | 20 | 55% | ~50s (mucho stock) |
| 15 | 150 | 30 | 40 | 60% | ~60s |

### Criterios de éxito:
✅ **Todas las piezas colocadas**: 100% de piezas cortadas  
✅ **Planchas dentro del límite**: No exceder max_plates_used  
✅ **Eficiencia aceptable**: >= min_efficiency  
✅ **Usa sobrantes primero**: Minimizar planchas nuevas  
✅ **Sin superposiciones**: Validación geométrica  
✅ **Tiempo razonable**: < 5 minutos por caso

---

## 🔍 Análisis de Resultados

### Ver los PDFs generados:
```bash
cd test_outputs/Producción_Alta_*/pdfs
ls -la
# Ver cuántas planchas se usaron y cómo se distribuyeron los cortes
```

### Comparar con expectativas:
```bash
# Ver si pasó o falló
cat test_outputs/Producción_Alta_*/RESUMEN.txt | grep -E "(CRITERIOS|piezas|planchas)"
```

### Identificar problemas:
Si un caso falla, verificar:
1. **¿Se colocaron todas las piezas?** → Ver "Piezas sin colocar"
2. **¿Usó demasiadas planchas?** → Ver "Planchas usadas" vs "Max planchas"
3. **¿Baja eficiencia?** → Ver "Eficiencia %" y "Sobrantes inútiles"
4. **¿Hay superposiciones?** → Ver PDFs visualmente

---

## 🛠️ Ajustar Tests

Si necesitas modificar los casos, edita:
```python
# optimizer/test/test_cases.py

CASE_HIGH_PRODUCTION = {
    "name": "Producción Alta: 100 piezas variadas con 20 sobrantes",
    "input": {
        "pieces_to_cut": [
            # Modificar aquí las piezas
        ]
    },
    "stock": {
        "scraps": [
            # Modificar aquí los sobrantes
        ],
        "glassplates": [
            # Modificar aquí las planchas nuevas
        ]
    },
    "expected": {
        "pieces_placed": 100,
        "max_plates_used": 15,  # Ajustar expectativas
        "min_efficiency": 65
    }
}
```

---

## 📚 Referencias

- **Casos simples (1-10)**: Tests unitarios básicos
- **Casos grandes (11-15)**: Tests de producción realistas
- **Makefile**: `make test-cases` para ejecutar todos
- **Visualización**: PDFs organizados por tipo de vidrio
- **Resumen**: RESUMEN.txt con estadísticas completas

---

## ✨ Próximos Pasos

1. **Ejecutar los tests**: `make test-cases`
2. **Revisar los PDFs**: Abrir los ZIPs generados
3. **Analizar fallos**: Ver qué casos no cumplen expectativas
4. **Ajustar el optimizador**: Si es necesario, modificar `cut_optimizer.py`
5. **Re-ejecutar**: Validar mejoras

🎯 **Objetivo**: Todos los 15 casos deben pasar exitosamente antes de ir a producción.
