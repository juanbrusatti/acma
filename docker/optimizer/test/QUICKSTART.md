# 🎯 Guía Rápida de Tests del Optimizador

## ⚡ Inicio Rápido

```bash
# Opción 1: Ejecutar todos los tests (sin PDFs, más rápido)
cd /home/mateo/Dlay/acma/docker/optimizer
make test

# Opción 2: Casos predefinidos CON PDFS y ZIPs ⭐
make test-cases
# Los PDFs se guardan en test_outputs/ organizados por test

# Opción 3: Tests unitarios guardando PDFs (más lento)
make test-with-pdfs

# Opción 4: Limpiar outputs antiguos
make clean-outputs
```

## 📋 Tests Disponibles

### 1. **Tests Unitarios** (`test_optimizer.py`)
- ✅ 25+ tests automatizados
- ⚡ Rápidos (~10 segundos)
- 🎯 Validan funciones individuales

### 2. **Casos Predefinidos** (`run_test_cases.py`)
- ✅ 10 escenarios reales
- 📊 Validación completa del flujo
- 🔍 Métricas detalladas
- 📦 **Genera ZIPs con PDFs y resumen para cada test** ⭐

**Estructura de outputs:**
```
test_outputs/
├── Simple_1_pieza_pequeña_20250117_143022/
│   ├── pdfs/
│   │   ├── Sobrante_scrap1.pdf  ← Ver cómo quedó el corte
│   │   └── LAM-3+3-INC/
│   ├── RESUMEN.txt  ← Estadísticas del test
│   └── *.zip  ← Todo comprimido
```

## 🚦 Workflow Recomendado

### Antes de hacer cambios:
```bash
make test  # ✅ Asegurar que todo funciona
```

### Hacer cambios en el código
Edita `cut_optimizer.py`, `visualize.py`, etc.

### Después de los cambios:
```bash
make test  # 🔍 Verificar que no rompiste nada
```

### Si algo falla:
1. Lee el mensaje de error detallado
2. Revisa qué test falló y por qué
3. Ajusta tu código o actualiza el test
4. Repite hasta que pase

## 📊 Ejemplos de Salida

### ✅ Tests exitosos:
```
======================================================================
📊 RESUMEN DE TESTS
======================================================================
✅ Tests exitosos: 25
❌ Tests fallidos: 0
======================================================================
```

### ❌ Test fallido:
```
FAIL: test_prefers_fewer_plates (__main__.TestQualityMetrics)
----------------------------------------------------------------------
AssertionError: 'Sobrante_scrap2' == 'Sobrante_scrap1'
Expected both pieces on same plate (scrap1)
```

## 🎨 Personalizacion

### Agregar un test rápido:

```python
# En test_optimizer.py
def test_mi_caso(self):
    """Mi descripción"""
    input_data = {...}
    stock_data = {...}
    plan, _, _, _ = run_optimizer(input_data, stock_data)
    self.assertEqual(len(plan), 5)  # Verificación
```

### Agregar caso complejo:

```python
# En test_cases.py
MI_CASO = {
    "name": "Mi caso especial",
    "input": {"pieces_to_cut": [...]},
    "stock": {"scraps": [...], "glassplates": [...]},
    "expected": {
        "pieces_placed": 10,
        "plates_used": 1,
        "max_waste_percent": 20
    }
}
ALL_TEST_CASES.append(MI_CASO)
```

## 🐛 Debugging

### Ver logs detallados:
```bash
python3 test/test_optimizer.py -v
```

### Ejecutar un solo test:
```bash
python3 -m unittest test_optimizer.TestBasicPacking.test_single_piece_fits_in_scrap
```

### Silenciar salida del optimizador:
```bash
python3 test/test_optimizer.py 2>/dev/null
```

## 📈 Métricas de Calidad

Los tests validan:
- ✅ Piezas colocadas correctamente
- ✅ Uso óptimo de planchas (menos es mejor)
- ✅ Sobrantes sin superposición
- ✅ Sobrantes grandes y reutilizables
- ✅ Eficiencia del corte
- ✅ Preservación de trazabilidad (ref_number)

## 🔧 Comandos Útiles

```bash
# Limpiar archivos temporales
make clean

# Ver ayuda
make help

# Ejecutar dentro de Docker
cd /home/mateo/Dlay/acma/docker
docker compose run --rm optimizer python test/test_optimizer.py
```

## 💡 Tips

1. **Ejecuta tests antes de cada commit**
2. **Agrega tests para bugs que encuentres**
3. **Mantén los tests actualizados con nuevas features**
4. **Si cambias la lógica del scoring, actualiza los tests**

## 🎓 Recursos

- `test/README.md` - Documentación completa
- `test/test_cases.py` - Ejemplos de casos reales
- `test/test_optimizer.py` - Código de los tests
