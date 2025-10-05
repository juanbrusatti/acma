# Optimizador de Cortes de Vidrio

## Descripción

El sistema de optimización de cortes de vidrio utiliza un algoritmo de guillotina para ubicar los cortes de un proyecto en planchas de vidrio, minimizando desperdicios y maximizando el uso de sobrantes existentes.

## Características principales

### 1. Priorización de sobrantes
- El algoritmo primero intenta ubicar cada corte en sobrantes disponibles (tabla `Scraps`)
- Solo usa planchas nuevas para cortes que no caben en sobrantes
- Verifica compatibilidad por: tipo de vidrio, espesor y color
- Considera ambas orientaciones (normal y rotada) para cada corte

### 2. Algoritmo de guillotina
- Implementa cortes solo horizontales y verticales (como una guillotina real)
- No permite cortes diagonales o complejos
- Usa técnica de bin packing First Fit Decreasing (ordena cortes por área)
- Divide rectángulos libres después de cada colocación

### 3. Gestión de sobrantes
- **Sobrantes reutilizables**: ≥ 200mm en alguna dimensión (gris claro en PDF)
- **Desperdicios**: < 200mm en ambas dimensiones (gris oscuro en PDF)
- Margen de corte: 5mm (ancho de sierra)

## Uso

### Desde la interfaz web
1. Navegar a la vista de un proyecto (show)
2. Hacer clic en el botón **"Optimizar"** (azul)
3. El sistema genera automáticamente un PDF con los planos de corte
4. El PDF se descarga y se guarda en `public/optimizations/{project_id}/`

### Desde código Ruby
```ruby
# Crear instancia del optimizador
optimizer = GlassCuttingOptimizer.new(project)

# Ejecutar optimización
cutting_plans = optimizer.optimize

# Cada plan contiene:
# - source_type: 'scrap' o 'plate'
# - source_id: ID del sobrante o plancha
# - plate_width, plate_height: dimensiones de la plancha
# - glass_type, thickness, color: tipo de vidrio
# - cuts: array de cortes con posiciones (x, y, width, height, rotated)
# - scraps: array de sobrantes generados
```

## Configuración

### Constantes ajustables en `GlassCuttingOptimizer`

```ruby
# Margen de corte en mm (ancho de la sierra)
CUTTING_MARGIN = 5

# Tamaño mínimo de sobrante reutilizable en mm
MIN_REUSABLE_SCRAP_SIZE = 200
```

## Estructura del PDF generado

### Por cada plancha:
1. **Información de la plancha**: tipo, dimensiones, origen (sobrante/nueva)
2. **Diagrama visual**: vista 2D con cortes posicionados y dimensionados
3. **Tabla de cortes**: detalle de cada corte con posición exacta
4. **Resumen de sobrantes**: lista de sobrantes generados con dimensiones

### Resumen general:
- Total de cortes procesados
- Cantidad de planchas utilizadas (sobrantes vs nuevas)
- Sobrantes generados (reutilizables vs desperdicios)
- Eficiencia de corte (% de aprovechamiento)

## Formato de los planos

Los planos se generan al estilo **Opticut**:
- Cortes en blanco con bordes negros y dimensiones
- Sobrantes reutilizables en gris claro (#b0b0b0)
- Desperdicios en gris oscuro (#505050)
- Escala automática para ajustar a página A4
- Todas las medidas en milímetros

## Requisitos previos

### Base de datos
1. Proyecto debe tener cortes (`glasscuttings` y/o `dvhs`)
2. Tabla `Glassplates` debe tener planchas disponibles del tipo requerido
3. Tabla `Scraps` con sobrantes disponibles (opcional)

### Gems
- `wicked_pdf`: generación de PDFs
- `wkhtmltopdf`: debe estar instalado en el sistema

## Flujo del algoritmo

```
1. Recopilar cortes del proyecto
   ├─ Glasscuttings simples
   └─ DVHs (2 vidrios por DVH)

2. Intentar ubicar en sobrantes
   ├─ Buscar sobrantes compatibles
   ├─ Verificar si cabe (normal o rotado)
   └─ Crear plan de corte si cabe

3. Agrupar cortes restantes por tipo de vidrio

4. Para cada grupo:
   ├─ Obtener plancha del tipo correcto
   ├─ Ordenar cortes por área (mayor a menor)
   └─ Empaquetar usando algoritmo guillotina
       ├─ Inicializar con rectángulo libre (plancha completa)
       ├─ Para cada corte:
       │   ├─ Buscar rectángulo libre que lo contenga
       │   ├─ Colocar corte (probar ambas orientaciones)
       │   ├─ Dividir rectángulo en 2 nuevos (horizontal + vertical)
       │   └─ Filtrar rectángulos muy pequeños
       └─ Calcular sobrantes de la plancha

5. Generar PDF con todos los planes de corte
```

## Limitaciones conocidas

1. **Algoritmo simplificado**: no es el óptimo global (NP-hard problem)
2. **Sin backtracking**: decisiones greedy pueden no dar mejor solución
3. **Sobrantes calculados de forma aproximada**: usa max_x y max_y en lugar de analizar huecos
4. **No considera defectos en vidrio**: asume planchas perfectas
5. **Rotación solo 90°**: no considera otras orientaciones

## Mejoras futuras

- [ ] Algoritmo de optimización más avanzado (branch & bound)
- [ ] Análisis de huecos internos para mejor cálculo de sobrantes
- [ ] Soporte para múltiples trabajadores (cortes paralelos)
- [ ] Registro de sobrantes generados automáticamente en tabla Scraps
- [ ] Interfaz para ajustar parámetros (margen, tamaño mínimo)
- [ ] Visualización interactiva en web antes de generar PDF
- [ ] Comparación de múltiples soluciones
- [ ] Exportación a formato DXF para máquinas CNC

## Soporte

Para problemas o preguntas sobre el optimizador, contactar al equipo de desarrollo.
