# 📦 Generación de ZIPs con PDFs en Tests - Guía Completa

## 🎯 Resumen

Ahora **cada test genera automáticamente**:
- 📄 **PDFs** de cada plancha usada (visualización del corte)
- 📝 **RESUMEN.txt** con estadísticas detalladas  
- 📦 **ZIP** con todo organizado

## 🚀 Uso Rápido

```bash
cd /home/mateo/Dlay/acma/docker/optimizer

# Ejecutar casos de test CON PDFs
make test-cases
# o
python3 test/run_test_cases.py

# Ver los resultados
ls -la test_outputs/
```

## 📁 Estructura de Salida

```
optimizer/
└── test_outputs/
    ├── Simple_1_pieza_pequeña_en_sobrante_grande_20251017_143022/
    │   ├── pdfs/
    │   │   └── FLO-4mm-INC/
    │   │       └── Sobrante_scrap1.pdf  ← ¡Ver el PDF del corte!
    │   ├── RESUMEN.txt  ← Estadísticas del test
    │   └── Simple_1_pieza_pequeña_en_sobrante_grande_20251017_143022.zip
    │
    ├── Múltiples_piezas_en_una_plancha_20251017_143025/
    │   ├── pdfs/
    │   │   └── LAM-3+3-INC/
    │   │       └── Sobrante_scrap1.pdf
    │   ├── RESUMEN.txt
    │   └── Múltiples_piezas_en_una_plancha_20251017_143025.zip
    │
    └── ...
```

## 📝 Ejemplo de RESUMEN.txt

```
======================================================================
RESUMEN DEL TEST: Simple: 1 pieza pequeña en sobrante grande
======================================================================

📊 ESTADÍSTICAS:
  • Piezas cortadas: 1
  • Piezas sin colocar: 0
  • Planchas usadas: 1
  • Sobrantes útiles: 2
  • Sobrantes inútiles: 0

🔨 PLANCHAS USADAS:
  • Sobrante_scrap1: 1000x1000
    - Tipo: Leftover
    - Piezas: 1
    - Ref: REF001

♻️  SOBRANTES ÚTILES (reutilizables):
  1. 1000x800 mm (Área: 800,000 mm²)
  2. 800x200 mm (Área: 160,000 mm²)

✅ CRITERIOS DE VALIDACIÓN:
  • pieces_placed: 1
  • plates_used: 1
  • should_use_scrap: True
  • max_waste_percent: 90

======================================================================
```

## 🎨 Visualización en PDFs

Cada PDF muestra:
- ✅ Piezas cortadas (azul claro) con sus IDs
- ✅ Sobrantes útiles (gris) con dimensiones
- ✅ Sobrantes inútiles (rosa) marcados
- ✅ Dimensiones de cada pieza
- ✅ Header con fecha y número de página
- ✅ Título con tipo de vidrio (LAM 3+3 INC, FLO 4mm INC, etc.)

## ⚙️ Configuración Avanzada

### Tests Unitarios con PDFs (opcional)

Por defecto, los tests unitarios **NO generan PDFs** (más rápidos).
Para habilitarlo:

```bash
# Linux/Mac
export SAVE_TEST_ARTIFACTS=true
make test-unit

# O directamente
SAVE_TEST_ARTIFACTS=true python3 test/test_optimizer.py
```

### Limpiar Outputs Antiguos

```bash
# Limpiar solo test_outputs/
make clean-outputs

# Limpiar todo (incluyendo __pycache__, etc.)
make clean
```

### Limpieza Automática

El sistema mantiene automáticamente solo los **últimos 10** test runs.
Los más antiguos se eliminan automáticamente para no llenar el disco.

## 🔍 Ver Resultados

### Opción 1: Descomprimir ZIP

```bash
cd test_outputs
unzip "Simple_1_pieza_pequeña_*.zip"
cd Simple_1_pieza_pequeña_*/pdfs
# Abrir PDFs con tu visor favorito
```

### Opción 2: Ver directamente la carpeta

```bash
cd test_outputs/Simple_1_pieza_pequeña_*/pdfs
ls -la
# Los PDFs ya están ahí, el ZIP es solo para compartir
```

## 📊 Análisis de Resultados

### 1. Revisar el RESUMEN.txt
```bash
cat test_outputs/Simple_*/RESUMEN.txt
```

### 2. Ver los PDFs generados
```bash
# Linux con evince/okular/etc
evince test_outputs/Simple_*/pdfs/*/*.pdf

# Mac
open test_outputs/Simple_*/pdfs/*/*.pdf
```

### 3. Comparar diferentes tests
```bash
# Ver qué tests pasaron/fallaron
ls -la test_outputs/

# Cada carpeta = un test ejecutado
# El nombre incluye timestamp para tracking
```

## 🎯 Casos de Uso

### Debugging: "¿Por qué falló este test?"

1. **Ejecutar el test:**
   ```bash
   make test-cases
   ```

2. **Ir a la carpeta del test:**
   ```bash
   cd test_outputs/[nombre_del_test]_*/
   ```

3. **Leer el resumen:**
   ```bash
   cat RESUMEN.txt
   # Verás qué pasó: piezas colocadas, sobrantes, etc.
   ```

4. **Ver el PDF:**
   ```bash
   open pdfs/*/*.pdf
   # Verás visualmente cómo quedó el corte
   ```

5. **Identificar el problema:**
   - ¿Hay superposiciones? → Ver en el PDF
   - ¿Sobrantes muy pequeños? → Ver estadísticas en RESUMEN.txt
   - ¿Usó más planchas de lo esperado? → Ver "PLANCHAS USADAS"

### Validación: "¿El optimizador mejoró?"

1. **Ejecutar tests ANTES de hacer cambios:**
   ```bash
   make test-cases
   # Los ZIPs se guardan con timestamp
   ```

2. **Hacer cambios en cut_optimizer.py**

3. **Ejecutar tests DESPUÉS:**
   ```bash
   make test-cases
   # Nuevo set de ZIPs con nuevo timestamp
   ```

4. **Comparar:**
   ```bash
   # Comparar RESUMEN.txt de antes y después
   diff test_outputs/Simple_*_143022/RESUMEN.txt \
        test_outputs/Simple_*_145530/RESUMEN.txt
   
   # Comparar visualmente los PDFs
   ```

### Compartir: "Mostrar resultados al equipo"

```bash
# Comprimir solo los ZIPs
cd test_outputs
zip -r all_tests_results.zip *.zip

# Enviar all_tests_results.zip
# El equipo puede ver cada test individualmente
```

## 🔧 Personalización

### Cambiar ubicación de outputs

Edita `test_utils.py`:
```python
def create_test_output_dir(test_name):
    base_dir = "mi_carpeta_custom"  # Cambiar aquí
    # ...
```

### Cambiar cantidad de tests a mantener

Edita `run_test_cases.py`:
```python
cleanup_old_test_outputs(keep_last_n=20)  # Mantener 20 en vez de 10
```

### Deshabilitar generación de ZIPs

En `test_utils.py`, comenta la línea:
```python
# zip_file = create_zip_archive(test_dir, test_name)
```

## 💡 Tips

1. **Los PDFs son A4 vertical** - perfectos para imprimir
2. **Cada PDF tiene múltiples páginas** si hay muchos cortes pequeños
3. **Los sobrantes están en gris/rosa** - fácil de distinguir
4. **Los ZIPs son pequeños** (< 500KB cada uno)
5. **La limpieza es automática** - no te preocupes por el espacio

## 🐛 Troubleshooting

### "No se generan PDFs"
```bash
# Verificar que matplotlib esté instalado
python3 -c "import matplotlib; print('OK')"

# Verificar permisos
ls -la test_outputs/
```

### "El ZIP está corrupto"
```bash
# Verificar integridad
unzip -t test_outputs/*.zip
```

### "Faltan PDFs en el ZIP"
```bash
# Ver qué se generó antes de comprimir
ls -la test_outputs/[nombre_test]_*/pdfs/
```

## 📚 Archivos Relacionados

- `test/test_utils.py` - Lógica de generación de artifacts
- `test/run_test_cases.py` - Runner que usa test_utils
- `test/test_optimizer.py` - Tests unitarios (opcional con PDFs)
- `visualize.py` - Generación de PDFs del optimizador
