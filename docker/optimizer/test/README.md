# 🧪 Test Suite para el Optimizador de Corte

Esta carpeta contiene una suite completa de tests para validar el funcionamiento del optimizador de corte de vidrio.

## 📁 Estructura

```
test/
├── test_optimizer.py      # Tests unitarios con unittest
├── test_cases.py          # Casos de test predefinidos
├── run_test_cases.py      # Runner para casos predefinidos
└── README.md             # Este archivo
```

## 🚀 Cómo ejecutar los tests

### Opción 1: Tests unitarios (unittest)

Ejecuta la suite completa de tests unitarios:

```bash
cd /home/mateo/Dlay/acma/docker/optimizer
python test/test_optimizer.py
```

**Tests incluidos:**
- ✅ Fusión de rectángulos adyacentes
- ✅ Empaquetado básico de piezas
- ✅ Detección de sobrantes (sin superposiciones)
- ✅ Optimización multi-etapa (sobrantes → planchas → emergencia)
- ✅ Manejo de rotaciones
- ✅ Casos extremos
- ✅ Métricas de calidad

### Opción 2: Casos de test predefinidos

Ejecuta casos de test con escenarios reales:

```bash
cd /home/mateo/Dlay/acma/docker/optimizer
python test/run_test_cases.py
```

**✨ NUEVO: Cada test genera automáticamente:**
- 📄 **PDFs** de cada plancha usada
- 📝 **Resumen.txt** con estadísticas detalladas
- 📦 **ZIP** con todo organizado

Los archivos se guardan en `test_outputs/` con estructura:
```
test_outputs/
├── Simple_1_pieza_pequeña_20250117_143022/
│   ├── pdfs/
│   │   ├── Sobrante_scrap1.pdf
│   │   └── ...
│   ├── RESUMEN.txt
│   └── Simple_1_pieza_pequeña_20250117_143022.zip
├── Múltiples_piezas_20250117_143025/
│   └── ...
```

**Casos incluidos:**
1. 🔹 Pieza pequeña en sobrante grande
2. 🔹 Múltiples piezas en una plancha
3. 🔹 Uso de planchas nuevas (ETAPA2)
4. 🔹 Rotación óptima
5. 🔹 Calidad de sobrantes (pocos y grandes)
6. 🔹 Plancha de emergencia (piezas muy grandes)
7. 🔹 Prioridad: usar menos planchas
8. 🔹 Stress test: 50 piezas pequeñas
9. 🔹 Validación: sin superposiciones
10. 🔹 Trazabilidad: preservar ref_number

### Opción 3: Ejecutar dentro del contenedor Docker

```bash
# Desde el directorio docker/
docker compose run --rm optimizer python test/test_optimizer.py
docker compose run --rm optimizer python test/run_test_cases.py
```

### Opción 4: Guardar PDFs en tests unitarios

Por defecto, los tests unitarios NO guardan PDFs (para ser más rápidos).
Para habilitar la generación de artifacts:

```bash
# Linux/Mac
export SAVE_TEST_ARTIFACTS=true
python test/test_optimizer.py

# Windows
set SAVE_TEST_ARTIFACTS=true
python test/test_optimizer.py
```

## 📊 Salida de ejemplo

```
🧪 SUITE DE TESTS DEL OPTIMIZADOR DE CORTE
======================================================================

test_empty_list (test_optimizer.TestMergeAdjacentRects) ... ok
test_merge_horizontal_adjacent (test_optimizer.TestMergeAdjacentRects) ... ok
test_merge_vertical_adjacent (test_optimizer.TestMergeAdjacentRects) ... ok
test_no_merge_non_adjacent (test_optimizer.TestMergeAdjacentRects) ... ok
test_piece_fits_in_new_plate (test_optimizer.TestBasicPacking) ... ok
test_single_piece_fits_in_scrap (test_optimizer.TestBasicPacking) ... ok
...

======================================================================
📊 RESUMEN DE TESTS
======================================================================
✅ Tests exitosos: 25
❌ Tests fallidos: 0
💥 Errores: 0
⏭️  Tests omitidos: 0
======================================================================
```

## 🛠️ Agregar nuevos tests

### 1. Agregar test unitario

Edita `test_optimizer.py` y agrega un nuevo método en la clase correspondiente:

```python
class TestBasicPacking(unittest.TestCase):
    def test_mi_nuevo_caso(self):
        """Descripción del test"""
        input_data = {...}
        stock_data = {...}
        
        plan, unpacked, bin_details, _ = run_optimizer(input_data, stock_data)
        
        # Tus aserciones
        self.assertEqual(len(unpacked), 0)
        self.assertGreater(len(plan), 0)
```

### 2. Agregar caso de test predefinido

Edita `test_cases.py` y agrega un nuevo caso:

```python
CASE_MI_CASO = {
    "name": "Mi caso de test",
    "input": {
        "pieces_to_cut": [...]
    },
    "stock": {
        "scraps": [...],
        "glassplates": [...]
    },
    "expected": {
        "pieces_placed": 5,
        "plates_used": 1,
        "should_use_scrap": True,
        "max_waste_percent": 50
    }
}

# Agregar a la lista
ALL_TEST_CASES.append(CASE_MI_CASO)
```

## ✅ Criterios de validación disponibles

En los casos predefinidos puedes usar estos criterios en `expected`:

| Criterio | Descripción | Ejemplo |
|----------|-------------|---------|
| `pieces_placed` | Número exacto de piezas colocadas | `5` |
| `plates_used` | Número exacto de planchas usadas | `1` |
| `max_plates_used` | Máximo de planchas permitidas | `<= 3` |
| `should_use_scrap` | Debe usar sobrantes | `True` |
| `plate_type` | Tipo de plancha esperado | `"New"` o `"Leftover"` |
| `should_use_emergency` | Debe usar plancha 3600x2500 | `True` |
| `max_unusable_waste_count` | Máximo de sobrantes inútiles | `<= 3` |
| `min_usable_waste_area` | Área mínima de sobrantes útiles | `>= 200000` |
| `min_avg_usable_size` | Tamaño promedio mínimo | `>= 100000` |
| `no_overlaps` | Sin superposiciones | `True` |
| `all_within_bounds` | Todo dentro de límites | `True` |
| `should_preserve_ref_number` | Preservar ref_number | `"REF001"` |
| `min_efficiency` | Eficiencia mínima % | `>= 70` |
| `max_waste_percent` | Máximo desperdicio % | `<= 30` |

## 🔄 Workflow recomendado

1. **Antes de hacer cambios**: Ejecuta `python test/test_optimizer.py` para asegurar que todo funciona
2. **Haz tus cambios** en `cut_optimizer.py`
3. **Ejecuta los tests** nuevamente
4. **Si algo falla**: Revisa qué cambió y ajusta según sea necesario
5. **Agrega tests** para nuevas funcionalidades

## 🎯 Tests críticos que siempre deben pasar

- ✅ Sin superposiciones de sobrantes con piezas
- ✅ Todas las piezas dentro de los límites de la plancha
- ✅ Prioridad de usar menos planchas
- ✅ Detección correcta de sobrantes útiles vs inútiles
- ✅ Preservación de ref_number para trazabilidad

## 📝 Notas

- Los tests pueden tardar unos segundos porque prueban múltiples heurísticas
- Si un test falla, revisa la salida detallada para ver qué criterio no se cumplió
- Puedes silenciar los prints del optimizador redirigiendo stderr: `2>/dev/null`

## 🐛 Debugging

Si necesitas ver logs detallados durante los tests:

```python
import logging
logging.basicConfig(level=logging.DEBUG)
```

O ejecuta con mayor verbosidad:

```bash
python test/test_optimizer.py -v
```
