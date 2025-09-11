# Sistema de Actualización Automática del Dólar Oficial

## Descripción

Este sistema implementa la actualización automática del dólar oficial del Banco Nación para el cálculo de precios de vidrios. Utiliza APIs gratuitas para obtener las cotizaciones en tiempo real y actualiza automáticamente todos los precios de insumos.

## Características

- ✅ **APIs gratuitas**: Utiliza DolarAPI y BCRA como fuentes de datos oficiales
- ✅ **Actualización automática**: Job programado que se ejecuta diariamente
- ✅ **Historial completo**: Almacena todas las cotizaciones con timestamps
- ✅ **Fallback inteligente**: Si la API principal falla, usa la API de respaldo
- ✅ **Interfaz web**: Botones para actualización manual y visualización del historial
- ✅ **Notificaciones**: Alerta sobre cambios significativos (>5%)

## Componentes Implementados

### 1. Servicio de API (`OfficialRateApiService`)
- Obtiene cotizaciones desde APIs gratuitas del dólar oficial
- Maneja errores y timeouts
- Sistema de fallback entre APIs

### 2. Modelo de Historial (`OfficialRateHistory`)
- Almacena cotizaciones históricas del dólar oficial
- Métodos para estadísticas y análisis
- Diferenciación entre actualizaciones manuales y automáticas

### 3. Job Automático (`UpdateOfficialRateJob`)
- Se ejecuta diariamente según configuración
- Actualiza precios de insumos automáticamente
- Notifica cambios significativos

### 4. Endpoints Web
- `POST /glass_prices/update_official_from_api` - Actualización manual desde API
- `GET /glass_prices/official_history` - Visualización del historial
- `PATCH /glass_prices/update_all_supplies_official` - Actualización manual con valor específico

## Configuración

### Horarios de Actualización Automática
- **Lunes a Viernes**: 9:00 AM
- **Sábados**: 10:00 AM
- **Domingos**: No se ejecuta (mercado cerrado)

### APIs Utilizadas
1. **DolarAPI Oficial** (Principal): `https://dolarapi.com/v1/dolares/oficial` - Endpoint específico para dólar oficial
2. **DolarAPI All** (Respaldo): `https://dolarapi.com/v1/dolares` - Busca "oficial" en la lista
3. **BCRA Oficial** (Último recurso): `https://api.bcra.gob.ar/estadisticas/v1/datosvariable/7930` - Datos oficiales del Banco Central

**Nota**: El sistema obtiene específicamente el dólar oficial del Banco Nación, que es más estable que el dólar MEP.

## Uso

### Actualización Manual
1. Ve a `/glass_prices`
2. Haz clic en el botón "API" para actualizar desde la API
3. O ingresa un valor manualmente y haz clic en "Actualizar"

### Ver Historial
1. Ve a `/glass_prices/official_history`
2. Visualiza estadísticas y cotizaciones históricas del dólar oficial
3. Ve el cambio porcentual vs el día anterior

### Configuración de Producción
El sistema está configurado para funcionar en producción usando `solid_queue` con tareas recurrentes definidas en `config/recurring.yml`.

## Archivos Modificados/Creados

### Nuevos Archivos
- `app/services/official_rate_api_service.rb` - Servicio para obtener cotizaciones del dólar oficial
- `app/models/official_rate_history.rb` - Modelo para historial de cotizaciones oficiales
- `app/jobs/update_official_rate_job.rb` - Job de actualización automática
- `app/views/glass_prices/official_history.html.erb` - Vista del historial
- `db/migrate/xxx_create_official_rate_histories.rb` - Migración de la tabla

### Archivos Modificados
- `app/models/app_config.rb` - Métodos para manejar historial del dólar oficial
- `app/controllers/glass_prices_controller.rb` - Nuevos endpoints para dólar oficial
- `config/routes.rb` - Rutas para nuevos endpoints
- `config/recurring.yml` - Configuración de tareas recurrentes
- `Gemfile` - Agregada dependencia `httparty`
- `app/views/glass_prices/index.html.erb` - Botones de control actualizados

## Dependencias

- `httparty` - Para hacer requests HTTP a las APIs externas

## Monitoreo

El sistema registra todas las operaciones en los logs de Rails:
- Actualizaciones exitosas del dólar oficial
- Errores de API
- Cambios significativos en las cotizaciones
- Fallbacks a APIs alternativas

## Consideraciones de Producción

1. **Rate Limiting**: Las APIs utilizadas son gratuitas pero pueden tener límites de uso
2. **Fallback**: Si ambas APIs fallan, el sistema usa la cotización del día anterior
3. **Logging**: Todos los eventos se registran para monitoreo
4. **Escalabilidad**: El job puede ejecutarse en múltiples workers sin conflictos
5. **Estabilidad**: El dólar oficial es más estable que el dólar MEP

## Próximas Mejoras Sugeridas

- [ ] Notificaciones por email para cambios significativos
- [ ] Dashboard con gráficos de evolución del dólar oficial
- [ ] API REST para consultar cotizaciones desde aplicaciones externas
- [ ] Configuración de horarios personalizables por usuario
- [ ] Integración con más fuentes de datos oficiales (Banco Nación directo, etc.)
