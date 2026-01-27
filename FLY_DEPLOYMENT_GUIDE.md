# 🚀 Guía de Despliegue ACMA en Fly.io

## 📋 Requisitos Previos

1. **Instalar Fly CLI**
```bash
curl -L https://fly.io/install.sh | sh
```

2. **Autenticarse**
```bash
flyctl auth login
```

3. **Crear cuenta en Supabase**
   - Ve a [supabase.com](https://supabase.com)
   - Crea un nuevo proyecto
   - Obtén la URL de la base de datos y las credenciales

## 🔧 Configuración de Variables de Entorno

### Para la Aplicación Rails (acma-rails)

```bash
# Configurar variables en Fly.io
flyctl secrets set DATABASE_URL="postgresql://postgres:[TU_PASSWORD]@[TU_PROYECTO].supabase.co:5432/postgres" -a acma-rails
flyctl secrets set RAILS_MASTER_KEY="[TU_RAILS_MASTER_KEY]" -a acma-rails
flyctl secrets set OPTIMIZER_URL="https://acma-optimizer.fly.dev/optimize" -a acma-rails
flyctl secrets set DB_SSLMODE="require" -a acma-rails
flyctl secrets set PROD_POSTGRES_DB="postgres" -a acma-rails
```

### Para el Optimizer (acma-optimizer)

```bash
# No se necesitan variables adicionales para el optimizer
# Pero puedes configurar si es necesario:
flyctl secrets set PYTHONUNBUFFERED="1" -a acma-optimizer
```

## 📦 Despliegue

### 1. Desplegar Aplicación Rails
```bash
cd /Users/juan/Desktop/acma/docker/Aberturas
flyctl launch --app acma-rails --region gru
# Seleccionar "yes" para sobreescribir fly.toml existente
# Seleccionar "yes" para desplegar ahora
```

### 2. Desplegar Optimizer
```bash
cd /Users/juan/Desktop/acma/docker/optimizer
flyctl launch --app acma-optimizer --region gru
# Seleccionar "yes" para sobreescribir fly.toml existente
# Seleccionar "yes" para desplegar ahora
```

## 🎛️ Optimización de Costos (Configuración Aplicada)

### Configuración de Máquinas:
- **Memoria**: 256MB (mínimo para Rails/Python)
- **CPU**: 1 shared CPU
- **Auto-stop**: Las máquinas se detienen automáticamente sin uso
- **Auto-start**: Las máquinas inician con tráfico
- **Mínimas máquinas corriendo**: 0

### Conexiones Concurrentes:
- **Límite duro**: 25 conexiones
- **Límite suave**: 20 conexiones

### Health Checks:
- **Rails**: `/up` cada 30 segundos
- **Optimizer**: `/health` cada 30 segundos

## 💰 Costos Estimados

Con esta configuración:
- **Uso bajo**: ~$5-10/mes (casi gratuito con créditos Fly.io)
- **Sin tráfico**: $0 (máquinas detenidas)
- **Base de datos**: Costo de Supabase (tier gratuito disponible)

## 🌐 URLs de Acceso

Una vez desplegado:
- **Aplicación Rails**: `https://acma-rails.fly.dev`
- **Optimizer API**: `https://acma-optimizer.fly.dev`
- **Health Rails**: `https://acma-rails.fly.dev/up`
- **Health Optimizer**: `https://acma-optimizer.fly.dev/health`

## 🔄 Comandos Útiles

### Ver estado de las aplicaciones:
```bash
flyctl status -a acma-rails
flyctl status -a acma-optimizer
```

### Ver logs:
```bash
flyctl logs -a acma-rails
flyctl logs -a acma-optimizer
```

### Escalar (si necesitas más recursos):
```bash
flyctl scale memory 512 -a acma-rails
flyctl scale vm shared-cpu-1x -a acma-rails
```

### Re-deploy después de cambios:
```bash
# Rails
cd /Users/juan/Desktop/acma/docker/Aberturas
flyctl deploy

# Optimizer
cd /Users/juan/Desktop/acma/docker/optimizer
flyctl deploy
```

## 🔍 Verificación Post-Despliegue

1. **Verificar que las aplicaciones están corriendo**:
```bash
curl https://acma-rails.fly.dev/up
curl https://acma-optimizer.fly.dev/health
```

2. **Verificar conexión a Supabase**:
   - Revisa los logs de Rails: `flyctl logs -a acma-rails`
   - Busca errores de conexión a la base de datos

3. **Probar la optimización**:
   - Ingresa a `https://acma-rails.fly.dev`
   - Intenta ejecutar una optimización
   - Verifica que se conecte al optimizer

## 🚨 Solución de Problemas

### Si la aplicación Rails no inicia:
```bash
flyctl ssh console -a acma-rails
# Verificar variables de entorno
env | grep -E "(DATABASE|RAILS)"
```

### Si el optimizer no responde:
```bash
flyctl ssh console -a acma-optimizer
# Verificar que el servicio está corriendo
ps aux | grep uvicorn
```

### Si hay problemas de conexión entre servicios:
- Verifica que `OPTIMIZER_URL` esté configurada correctamente
- Asegúrate de que ambos servicios estén en la misma región (gru)

## 📝 Notas Importantes

1. **Region**: Configurado para `gru` (São Paulo) para mejor latencia en Argentina
2. **SSL**: Todo el tráfico es redirigido a HTTPS automáticamente
3. **Backups**: Configura backups automáticos en Supabase
4. **Monitoreo**: Usa los endpoints de health para monitoreo externo
5. **Dominio personalizado**: Puedes configurar un dominio personalizado después del despliegue
