# 🔧 GUÍA DE OPERACIONES Y TROUBLESHOOTING - ACMA

Esta guía complementa el README principal con información específica para la operación diaria, solución de problemas avanzados y escenarios especiales.

---

## 📖 **ÍNDICE RÁPIDO**

1. [Comandos de Emergencia](#-comandos-de-emergencia)
2. [Diagnóstico Rápido](#-diagnóstico-rápido)
3. [Problemas Específicos](#-problemas-específicos)
4. [Optimización de Rendimiento](#-optimización-de-rendimiento)
5. [Mantenimiento Avanzado](#-mantenimiento-avanzado)
6. [Escenarios de Recuperación](#-escenarios-de-recuperación)
7. [Configuración Avanzada](#-configuración-avanzada)
8. [Monitoreo Automático](#-monitoreo-automático)

---

## 🚨 **COMANDOS DE EMERGENCIA**

### **Reinicio Completo (Último Recurso):**
```bash
# Parar todo y limpiar
docker compose down --remove-orphans
docker system prune -f

# Reiniciar desde cero
docker compose up -d --build

# Verificar estado
docker compose ps
curl -I http://localhost:3000
```

### **Backup de Emergencia (30 segundos):**
```bash
# Backup rápido antes de cambios críticos
echo "2" | ./backup-database.sh

# Backup con timestamp específico
docker compose exec -T db pg_dump -U postgres acma_production > emergency_backup_$(date +%Y%m%d_%H%M%S).sql
```

### **Recuperación de Datos Críticos:**
```bash
# Si la DB está corrupta pero el contenedor funciona
docker compose exec db pg_dumpall -U postgres > full_emergency_backup.sql

# Si el contenedor no responde
docker cp docker-db-1:/var/lib/postgresql/data ./emergency_data_recovery/
```

### **Reinicio de Red Docker:**
```bash
# Si hay problemas de conectividad
docker network prune -f
docker compose down
docker compose up -d
```

---

## 🔍 **DIAGNÓSTICO RÁPIDO**

### **Script de Diagnóstico Automático:**

```bash
#!/bin/bash
# diagnostic.sh - Diagnóstico completo del sistema ACMA

echo "=== DIAGNÓSTICO ACMA $(date) ==="

# 1. Estado de Docker
echo "1. DOCKER:"
docker --version
docker compose version
docker info | grep -E "Server Version|Storage Driver|Containers|Images"

# 2. Estado de Servicios
echo -e "\n2. SERVICIOS:"
docker compose ps

# 3. Recursos del Sistema
echo -e "\n3. RECURSOS:"
echo "CPU y Memoria:"
docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}"

echo -e "\nEspacio en Disco:"
df -h | grep -E "Filesystem|$(pwd)"

# 4. Red
echo -e "\n4. RED:"
echo "Puertos abiertos:"
netstat -tlnp | grep -E "3000|5432"

echo "Conectividad local:"
curl -I http://localhost:3000 2>/dev/null || echo "ERROR: No hay respuesta HTTP"

# 5. Base de Datos
echo -e "\n5. BASE DE DATOS:"
if docker compose exec -T db pg_isready -U postgres >/dev/null 2>&1; then
    echo "PostgreSQL: FUNCIONANDO"
    echo "Tamaño de DB:"
    docker compose exec -T db psql -U postgres -d acma_production \
        -c "SELECT pg_size_pretty(pg_database_size('acma_production'));" -t | tr -d ' '
    echo "Conexiones activas:"
    docker compose exec -T db psql -U postgres -d acma_production \
        -c "SELECT count(*) FROM pg_stat_activity;" -t | tr -d ' '
else
    echo "PostgreSQL: ERROR"
fi

# 6. Logs de Errores Recientes
echo -e "\n6. ERRORES RECIENTES:"
docker compose logs --tail=10 | grep -i error || echo "No hay errores recientes"

# 7. Configuración
echo -e "\n7. CONFIGURACIÓN:"
echo "IP del servidor: $(grep RAILS_HOST .env | cut -d'=' -f2)"
echo "Puerto: $(grep RAILS_PORT .env | cut -d'=' -f2)"
echo "Base de datos: $(grep POSTGRES_DB .env | cut -d'=' -f2)"

echo -e "\n=== FIN DIAGNÓSTICO ==="
```

### **Diagnóstico de Red:**

```bash
#!/bin/bash
# network-diagnostic.sh

echo "=== DIAGNÓSTICO DE RED ==="

# IP del servidor
SERVER_IP=$(grep RAILS_HOST .env | cut -d'=' -f2)
SERVER_PORT=$(grep RAILS_PORT .env | cut -d'=' -f2)

echo "Configuración del servidor:"
echo "IP: $SERVER_IP"
echo "Puerto: $SERVER_PORT"

# Verificar acceso local
echo -e "\nPrueba de acceso local:"
curl -I http://localhost:$SERVER_PORT

# Verificar acceso por IP
echo -e "\nPrueba de acceso por IP:"
curl -I http://$SERVER_IP:$SERVER_PORT

# Verificar puertos en uso
echo -e "\nPuertos en uso:"
netstat -tlnp | grep $SERVER_PORT

# Verificar firewall (Linux)
if command -v ufw >/dev/null; then
    echo -e "\nEstado del firewall:"
    sudo ufw status | grep $SERVER_PORT
fi

# Ping desde otra red (si es posible)
echo -e "\nDesde otra PC en la red, ejecutar:"
echo "curl -I http://$SERVER_IP:$SERVER_PORT"
echo "ping $SERVER_IP"
```

---

## 🔧 **PROBLEMAS ESPECÍFICOS**

### **1. "Rails server no responde"**

**Síntomas:**
- Docker compose ps muestra web como "Restarting"
- Logs muestran errores de inicialización
- Puerto 3000 no responde

**Diagnóstico:**
```bash
# Ver logs detallados
docker compose logs web --tail=50

# Verificar variables de entorno
docker compose exec web env | grep -E "RAILS|DATABASE"

# Probar conexión a DB desde web
docker compose exec web rails runner "puts ActiveRecord::Base.connection.active?"
```

**Soluciones:**
```bash
# 1. Verificar configuración de DB
docker compose exec -T db psql -U postgres -l

# 2. Recrear base de datos si es necesario
docker compose exec web rails db:create
docker compose exec web rails db:migrate

# 3. Reconstruir contenedor web
docker compose stop web
docker compose build web --no-cache
docker compose up -d web

# 4. Si persiste, verificar Gemfile.lock
docker compose exec web bundle install
```

### **2. "PostgreSQL no inicia"**

**Síntomas:**
- Container db en estado "Exited"
- Logs muestran errores de inicialización
- pg_isready falla

**Diagnóstico:**
```bash
# Logs de PostgreSQL
docker compose logs db

# Verificar permisos de postgres_data
ls -la postgres_data/

# Verificar espacio en disco
df -h
```

**Soluciones:**
```bash
# 1. Verificar permisos (Linux)
sudo chown -R 999:999 postgres_data/

# 2. Si hay corrupción, backup y recrear
docker compose down
mv postgres_data postgres_data_corrupted
docker compose up -d db

# 3. Restaurar desde backup
./restore-database.sh

# 4. Si falla todo, reset completo
docker compose down -v
rm -rf postgres_data
docker compose up -d
```

### **3. "No puedo conectar desde aplicaciones cliente"**

**Síntomas:**
- Servidor funciona localmente
- Aplicaciones Electron no pueden conectar
- Timeout en conexiones remotas

**Diagnóstico completo:**
```bash
# 1. Verificar IP configurada
grep RAILS_HOST .env

# 2. Verificar IP real del servidor
# Windows: ipconfig
# Linux: ip addr show

# 3. Verificar firewall
# Windows: netsh advfirewall show allprofiles
# Linux: sudo ufw status

# 4. Probar desde otra PC
# En otra PC: telnet IP_SERVIDOR 3000
```

**Soluciones:**
```bash
# 1. Corregir IP en .env
sed -i 's/RAILS_HOST=.*/RAILS_HOST=IP_REAL_AQUI/' .env

# 2. Configurar firewall
# Windows (PowerShell como Admin):
New-NetFirewallRule -DisplayName "ACMA" -Direction Inbound -Protocol TCP -LocalPort 3000 -Action Allow

# Linux:
sudo ufw allow 3000

# 3. Verificar binding en Rails
# Asegurar que Rails escuche en 0.0.0.0, no 127.0.0.1

# 4. Reiniciar servicios
docker compose restart web
```

### **4. "Rendimiento lento"**

**Síntomas:**
- Respuestas HTTP lentas (>5 segundos)
- Alto uso de CPU/RAM
- Aplicaciones cliente timeout

**Diagnóstico:**
```bash
# Recursos en tiempo real
docker stats

# I/O de disco
docker compose exec db iotop -o

# Consultas lentas en DB
docker compose exec db psql -U postgres -d acma_production \
  -c "SELECT query, calls, total_time, mean_time FROM pg_stat_statements ORDER BY total_time DESC LIMIT 10;"

# Logs de rendimiento
docker compose logs web | grep -i "Completed.*in.*ms"
```

**Optimizaciones:**
```bash
# 1. Aumentar recursos Docker
# Docker Desktop → Settings → Resources → Memory: 8GB, CPU: 4

# 2. Optimizar PostgreSQL
docker compose exec db psql -U postgres -d acma_production -c "
  VACUUM ANALYZE;
  REINDEX DATABASE acma_production;
"

# 3. Configurar PostgreSQL para producción
cat >> init-scripts/02-performance.sql << EOF
ALTER SYSTEM SET shared_buffers = '256MB';
ALTER SYSTEM SET effective_cache_size = '1GB';
ALTER SYSTEM SET maintenance_work_mem = '64MB';
ALTER SYSTEM SET checkpoint_completion_target = 0.9;
SELECT pg_reload_conf();
EOF

# 4. Limpiar logs de Rails
docker compose exec web sh -c "find /app/log -name '*.log' -exec truncate -s 0 {} \;"
```

---

## ⚡ **OPTIMIZACIÓN DE RENDIMIENTO**

### **Configuración Optimizada de PostgreSQL:**

```sql
-- 03-production-tuning.sql
-- Configuración optimizada para servidor de producción

-- Memoria
ALTER SYSTEM SET shared_buffers = '512MB';              -- 25% de RAM total
ALTER SYSTEM SET effective_cache_size = '2GB';          -- 75% de RAM total
ALTER SYSTEM SET work_mem = '8MB';                       -- Por conexión
ALTER SYSTEM SET maintenance_work_mem = '128MB';        -- Para VACUUM, CREATE INDEX

-- Checkpoints y WAL
ALTER SYSTEM SET wal_buffers = '16MB';
ALTER SYSTEM SET checkpoint_completion_target = 0.9;
ALTER SYSTEM SET checkpoint_timeout = '15min';
ALTER SYSTEM SET max_wal_size = '2GB';
ALTER SYSTEM SET min_wal_size = '80MB';

-- Conexiones
ALTER SYSTEM SET max_connections = 100;
ALTER SYSTEM SET shared_preload_libraries = 'pg_stat_statements';

-- Logging para monitoreo
ALTER SYSTEM SET log_min_duration_statement = 1000;     -- Log queries > 1 segundo
ALTER SYSTEM SET log_connections = on;
ALTER SYSTEM SET log_disconnections = on;

SELECT pg_reload_conf();
```

### **Monitoreo de Rendimiento:**

```bash
#!/bin/bash
# performance-monitor.sh

echo "=== MONITOR DE RENDIMIENTO ACMA ==="

# CPU y Memoria
echo "1. RECURSOS DEL SISTEMA:"
docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}"

# Espacio en disco
echo -e "\n2. ESPACIO EN DISCO:"
df -h | grep -E "Filesystem|$(pwd)"
du -sh postgres_data/ backups/

# Base de datos
echo -e "\n3. ESTADÍSTICAS DE BASE DE DATOS:"
docker compose exec -T db psql -U postgres -d acma_production << 'EOF'
-- Tamaño de base de datos
SELECT pg_size_pretty(pg_database_size('acma_production')) as database_size;

-- Conexiones activas
SELECT count(*) as active_connections FROM pg_stat_activity WHERE state = 'active';

-- Tablas más grandes
SELECT schemaname,tablename,pg_size_pretty(size) as size
FROM (
  SELECT schemaname,tablename,pg_total_relation_size(schemaname||'.'||tablename) as size
  FROM (
    SELECT schemaname, tablename FROM pg_tables
    WHERE schemaname NOT LIKE 'pg_%' AND schemaname != 'information_schema'
  ) as tables
  ORDER BY size DESC LIMIT 5
) as formatted;

-- Consultas más lentas (si pg_stat_statements está habilitado)
SELECT query, calls, total_time, mean_time
FROM pg_stat_statements
ORDER BY total_time DESC LIMIT 5;
EOF

# Logs de errores recientes
echo -e "\n4. ERRORES RECIENTES:"
docker compose logs --tail=20 | grep -i -E "error|exception|fatal" | tail -5

# Red
echo -e "\n5. CONECTIVIDAD:"
SERVER_IP=$(grep RAILS_HOST .env | cut -d'=' -f2)
curl -o /dev/null -s -w "Tiempo de respuesta HTTP: %{time_total}s\n" http://$SERVER_IP:3000/

echo -e "\n=== FIN MONITOR ==="
```

---

## 🛠️ **MANTENIMIENTO AVANZADO**

### **Script de Mantenimiento Automático:**

```bash
#!/bin/bash
# maintenance.sh - Mantenimiento automático del sistema

LOG_FILE="/var/log/acma-maintenance.log"
BACKUP_RETENTION_DAYS=30

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

log "=== INICIANDO MANTENIMIENTO ACMA ==="

# 1. Verificar estado del sistema
log "Verificando estado del sistema..."
if ! docker compose ps | grep -q "Up"; then
    log "ERROR: Servicios no están corriendo. Abortando mantenimiento."
    exit 1
fi

# 2. Backup automático
log "Creando backup automático..."
echo "4" | ./backup-database.sh >> "$LOG_FILE" 2>&1

# 3. Limpiar backups antiguos
log "Limpiando backups antiguos (más de $BACKUP_RETENTION_DAYS días)..."
find backups/ -name "backup_acma_*" -mtime +$BACKUP_RETENTION_DAYS -delete

# 4. Optimizar base de datos
log "Optimizando base de datos..."
docker compose exec -T db psql -U postgres -d acma_production << 'EOF' >> "$LOG_FILE" 2>&1
VACUUM ANALYZE;
REINDEX DATABASE acma_production;
EOF

# 5. Limpiar logs de aplicación
log "Limpiando logs de aplicación..."
docker compose exec web sh -c "find /app/log -name '*.log' -exec truncate -s 1M {} \;" >> "$LOG_FILE" 2>&1

# 6. Limpiar Docker
log "Limpiando sistema Docker..."
docker system prune -f >> "$LOG_FILE" 2>&1

# 7. Verificar integridad
log "Verificando integridad del sistema..."
ERRORS=$(docker compose logs --tail=100 | grep -c -i error)
log "Errores encontrados en logs: $ERRORS"

# 8. Generar reporte
log "Generando reporte de estado..."
{
    echo "=== REPORTE DE MANTENIMIENTO $(date) ==="
    echo "Estado de servicios:"
    docker compose ps
    echo
    echo "Uso de recursos:"
    docker stats --no-stream
    echo
    echo "Espacio en disco:"
    df -h
    echo
    echo "Tamaño de base de datos:"
    docker compose exec -T db psql -U postgres -d acma_production \
        -c "SELECT pg_size_pretty(pg_database_size('acma_production'));" -t
} >> "$LOG_FILE"

log "=== MANTENIMIENTO COMPLETADO ==="

# Enviar notificación (opcional)
# mail -s "Mantenimiento ACMA Completado" admin@empresa.com < "$LOG_FILE"
```

### **Configuración de Logrotate:**

```bash
# /etc/logrotate.d/acma
/var/log/acma-maintenance.log {
    daily
    rotate 30
    compress
    delaycompress
    missingok
    notifempty
    copytruncate
}

/opt/acma/docker/backups/*.log {
    weekly
    rotate 4
    compress
    delaycompress
    missingok
    notifempty
}
```

---

## 🚀 **ESCENARIOS DE RECUPERACIÓN**

### **Escenario 1: Corrupción de Base de Datos**

```bash
# Detección
docker compose exec db psql -U postgres -d acma_production -c "SELECT 1;"
# Si falla: "FATAL: database is corrupted"

# Recuperación
log "EMERGENCIA: Detectada corrupción de base de datos"

# 1. Parar servicios
docker compose stop web

# 2. Intentar backup de emergencia
docker compose exec db pg_dumpall -U postgres > emergency_full_backup.sql

# 3. Parar DB y respaldar datos físicos
docker compose stop db
mv postgres_data postgres_data_corrupted_$(date +%Y%m%d)

# 4. Restaurar desde último backup válido
./restore-database.sh
# Seleccionar último backup completo

# 5. Verificar integridad
docker compose up -d
docker compose exec db psql -U postgres -d acma_production -c "SELECT count(*) FROM pg_tables;"
```

### **Escenario 2: Falla Completa del Servidor**

```bash
# En nueva máquina/después de reinstalar OS

# 1. Instalar Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

# 2. Restaurar archivos del proyecto
# Copiar carpeta completa desde backup externo

# 3. Restaurar datos desde backup
cd /opt/acma/docker
./restore-database.sh

# 4. Configurar red si cambió IP
./configurar-postgres.bat  # o editar .env manualmente

# 5. Iniciar servicios
./start-server.sh

# 6. Verificar funcionalidad completa
curl -I http://localhost:3000
```

### **Escenario 3: Actualización Fallida**

```bash
# Si una actualización falla y necesitas rollback

# 1. Parar servicios actuales
docker compose down

# 2. Restaurar código anterior
rm -rf Aberturas
mv Aberturas_backup_$(date +%Y%m%d) Aberturas

# 3. Restaurar configuraciones
mv .env.backup .env
mv docker-compose.yml.backup docker-compose.yml

# 4. Restaurar base de datos pre-actualización
./restore-database.sh
# Seleccionar backup anterior a la actualización

# 5. Reconstruir con versión anterior
docker compose build --no-cache
docker compose up -d

# 6. Verificar funcionalidad
./diagnostic.sh
```

---

## 📊 **MONITOREO AUTOMÁTICO**

### **Script de Monitoreo con Alertas:**

```bash
#!/bin/bash
# monitor-alerts.sh - Sistema de alertas automático

ALERT_EMAIL="admin@empresa.com"
ALERT_THRESHOLD_CPU=80
ALERT_THRESHOLD_MEM=85
ALERT_THRESHOLD_DISK=90

send_alert() {
    local subject="$1"
    local message="$2"
    echo "$message" | mail -s "ALERTA ACMA: $subject" "$ALERT_EMAIL"
    logger "ACMA ALERT: $subject - $message"
}

# Verificar servicios corriendo
if ! docker compose ps | grep -q "Up"; then
    send_alert "Servicios Caídos" "Los servicios de ACMA no están corriendo. Verificar inmediatamente."
fi

# Verificar uso de CPU
CPU_USAGE=$(docker stats --no-stream --format "{{.CPUPerc}}" | head -1 | sed 's/%//')
if (( $(echo "$CPU_USAGE > $ALERT_THRESHOLD_CPU" | bc -l) )); then
    send_alert "CPU Alta" "Uso de CPU: ${CPU_USAGE}%. Umbral: ${ALERT_THRESHOLD_CPU}%"
fi

# Verificar uso de memoria
MEM_USAGE=$(docker stats --no-stream --format "{{.MemPerc}}" | head -1 | sed 's/%//')
if (( $(echo "$MEM_USAGE > $ALERT_THRESHOLD_MEM" | bc -l) )); then
    send_alert "Memoria Alta" "Uso de memoria: ${MEM_USAGE}%. Umbral: ${ALERT_THRESHOLD_MEM}%"
fi

# Verificar espacio en disco
DISK_USAGE=$(df -h | grep -E "$(pwd)" | awk '{print $5}' | sed 's/%//')
if [ "$DISK_USAGE" -gt "$ALERT_THRESHOLD_DISK" ]; then
    send_alert "Disco Lleno" "Uso de disco: ${DISK_USAGE}%. Umbral: ${ALERT_THRESHOLD_DISK}%"
fi

# Verificar conectividad
if ! curl -f -s http://localhost:3000 >/dev/null; then
    send_alert "Web No Responde" "El servidor web no responde en puerto 3000"
fi

# Verificar base de datos
if ! docker compose exec -T db pg_isready -U postgres >/dev/null 2>&1; then
    send_alert "Base de Datos Caída" "PostgreSQL no responde"
fi

# Verificar logs de errores
ERROR_COUNT=$(docker compose logs --tail=100 | grep -c -i "error\|exception\|fatal")
if [ "$ERROR_COUNT" -gt 5 ]; then
    send_alert "Múltiples Errores" "Detectados $ERROR_COUNT errores en logs recientes"
fi
```

### **Dashboard Simple en HTML:**

```html
<!DOCTYPE html>
<html>
<head>
    <title>ACMA Server Status</title>
    <meta http-equiv="refresh" content="30">
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .status { padding: 10px; margin: 5px; border-radius: 5px; }
        .ok { background-color: #d4edda; border: 1px solid #c3e6cb; }
        .warning { background-color: #fff3cd; border: 1px solid #ffeaa7; }
        .error { background-color: #f8d7da; border: 1px solid #f5c6cb; }
    </style>
</head>
<body>
    <h1>ACMA Server Status Dashboard</h1>
    <p>Última actualización: <span id="timestamp"></span></p>

    <div id="status-container">
        <!-- Se llena con JavaScript -->
    </div>

    <script>
        function updateStatus() {
            fetch('/api/status')
                .then(response => response.json())
                .then(data => {
                    const container = document.getElementById('status-container');
                    container.innerHTML = '';

                    data.checks.forEach(check => {
                        const div = document.createElement('div');
                        div.className = `status ${check.status}`;
                        div.innerHTML = `<strong>${check.name}:</strong> ${check.message}`;
                        container.appendChild(div);
                    });

                    document.getElementById('timestamp').textContent = new Date().toLocaleString();
                })
                .catch(error => {
                    console.error('Error updating status:', error);
                });
        }

        // Actualizar cada 30 segundos
        updateStatus();
        setInterval(updateStatus, 30000);
    </script>
</body>
</html>
```

---

## 📋 **CHECKLIST DE TROUBLESHOOTING**

### **Problema: Servidor No Responde**
```markdown
- [ ] Docker Desktop está corriendo
- [ ] docker compose ps muestra servicios "Up"
- [ ] Puerto 3000 está abierto (netstat -tlnp | grep 3000)
- [ ] Firewall permite conexiones al puerto 3000
- [ ] IP en .env coincide con IP real del servidor
- [ ] No hay conflictos de puerto (otro servicio en 3000)
- [ ] Logs no muestran errores críticos
```

### **Problema: Base de Datos No Funciona**
```markdown
- [ ] Container 'db' está corriendo
- [ ] pg_isready responde positivamente
- [ ] postgres_data/ tiene permisos correctos
- [ ] Hay espacio suficiente en disco
- [ ] No hay corrupción de archivos (.pid, .lock)
- [ ] Variables de entorno DB son correctas
- [ ] Puerto 5432 no está en uso por otro PostgreSQL
```

### **Problema: Rendimiento Lento**
```markdown
- [ ] CPU < 80% (docker stats)
- [ ] Memoria < 90% (docker stats)
- [ ] Disco con espacio suficiente (df -h)
- [ ] No hay consultas SQL lentas (pg_stat_statements)
- [ ] Logs de Rails sin errores repetitivos
- [ ] Base de datos optimizada (VACUUM, ANALYZE)
- [ ] Docker tiene recursos suficientes asignados
```

---

**📝 Última actualización**: $(date)
**📧 Soporte Técnico**: [soporte@empresa.com]
**🚨 Emergencias**: [teléfono-24/7]
