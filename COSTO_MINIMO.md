# 💰 Configuración de Costo Mínimo Absoluto - ACMA

## 🎯 **Objetivo: Costo Mínimo Posible**

### 📊 **Configuración Aplicada:**

#### **Rails (acma-rails)**
- **Memoria**: 256MB (mínimo viable)
- **CPU**: 1 shared CPU
- **Máquinas mínimas**: 0 (se detienen sin uso)
- **Auto-stop**: ✅ Se detiene automáticamente
- **Auto-start**: ✅ Inicia con tráfico
- **Concurrencia**: 8 suaves, 10 duras (reducido)
- **Health checks**: Cada 2 minutos (menos frecuentes)

#### **Optimizer (acma-optimizer)**
- **Memoria**: 256MB (mínimo viable)
- **CPU**: 1 shared CPU
- **Máquinas mínimas**: 0 (se detienen sin uso)
- **Auto-stop**: ✅ Se detiene automáticamente
- **Auto-start**: ✅ Inicia con tráfico
- **Concurrencia**: 3 suaves, 5 duras (mínimo)
- **Health checks**: Cada 2 minutos (menos frecuentes)

### 💵 **Costo Estimado:**

#### **Sin Uso (máquinas detenidas):**
- **Rails**: $0.00
- **Optimizer**: $0.00
- **Total**: $0.00

#### **Uso Bajo (pocas horas al día):**
- **Rails**: ~$2-3/mes
- **Optimizer**: ~$2-3/mes
- **Total**: ~$4-6/mes

#### **Uso Moderado (varias horas al día):**
- **Rails**: ~$4-5/mes
- **Optimizer**: ~$4-5/mes
- **Total**: ~$8-10/mes

### ⏱️ **Comportamiento:**

1. **Sin tráfico**: Ambas aplicaciones detenidas = $0
2. **Primer request**: ~30-60 segundos para iniciar
3. **Con tráfico**: Solo paga mientras hay uso activo
4. **Sin uso por 5 min**: Se detienen automáticamente

### 🛠️ **Optimizaciones Aplicadas:**

- ✅ **Health checks menos frecuentes**: 2 minutos (vs 30s)
- ✅ **Grace period extendido**: 60 segundos para iniciar
- ✅ **Concurrencia mínima**: Solo conexiones necesarias
- ✅ **Memoria mínima**: 256MB (justo para Rails/Python)
- ✅ **Sin máquinas reservadas**: 0 mínimas corriendo

### 📈 **Monitoreo de Costos:**

```bash
# Ver consumo actual
flyctl usage

# Ver estado de máquinas
flyctl status -a acma-rails
flyctl status -a acma-optimizer

# Ver logs para detectar actividad
flyctl logs -a acma-rails --since 1h
flyctl logs -a acma-optimizer --since 1h
```

### 🎛️ **Para Reducir Costos Aún Más:**

1. **Usar solo cuando sea necesario**
2. **Evitar requests automáticos frecuentes**
3. **Considerar desactivar optimizer si no se usa**
4. **Monitorear uso regularmente**

### ⚠️ **Limitaciones:**

- **Latencia inicial**: 30-60 segundos al iniciar
- **Concurrencia baja**: Máximo 10-15 usuarios simultáneos
- **Recursos limitados**: Puede ser lento con mucho uso

### 🔄 **Pasos Siguientes:**

1. **Agregar método de pago** en https://fly.io/trial
2. **Desplegar cambios**:
   ```bash
   cd /Users/juan/Desktop/acma/docker/Aberturas && flyctl deploy
   cd /Users/juan/Desktop/acma/docker/optimizer && flyctl deploy
   ```
3. **Probar funcionamiento**
4. **Monitorear costos** durante la primera semana

### 💡 **Consejo:**
Esta configuración es ideal para:
- Desarrollo y testing
- Uso ocasional o personal
- Prototipos y demos
- Proyectos con bajo tráfico

Para producción con alto tráfico, considerar aumentar recursos gradualmente.
