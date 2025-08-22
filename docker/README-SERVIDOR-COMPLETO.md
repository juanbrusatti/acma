# 📚 GUÍA COMPLETA DEL SERVIDOR ACMA - MANUAL TÉCNICO DEFINITIVO

Esta es la guía técnica completa para la instalación, configuración y mantenimiento del servidor ACMA con PostgreSQL. Incluye todo lo necesario para administrar el sistema desde cero hasta producción.

---

## 📖 **ÍNDICE**

1. [Requisitos del Sistema](#-requisitos-del-sistema)
2. [Instalación Primera Vez](#-instalación-primera-vez)
3. [Configuración del Sistema](#-configuración-del-sistema)
4. [Scripts y Herramientas](#-scripts-y-herramientas)
5. [Operación Diaria](#-operación-diaria)
6. [Sistema de Backups](#-sistema-de-backups)
7. [Monitoreo y Mantenimiento](#-monitoreo-y-mantenimiento)
8. [Solución de Problemas](#-solución-de-problemas)
9. [Seguridad](#-seguridad)
10. [Futuras Actualizaciones](#-futuras-actualizaciones)
11. [Checklist Completo](#-checklist-completo)

---

## 💻 **REQUISITOS DEL SISTEMA**

### **Hardware Mínimo:**
- **RAM**: 4 GB (8 GB recomendado para mejor rendimiento)
- **CPU**: Procesador dual-core x64 (quad-core recomendado)
- **Almacenamiento**: 20 GB libres (50 GB recomendado)
- **Red**: Ethernet 100 Mbps (Gigabit recomendado)

### **Hardware Recomendado:**
- **RAM**: 16 GB o más
- **CPU**: Intel i5/AMD Ryzen 5 o superior
- **Almacenamiento**: SSD de 100 GB o más
- **Red**: Gigabit Ethernet con IP estática

### **Software Requerido:**
- **Windows**: Windows 10 Pro/Enterprise o Windows 11 (con Hyper-V)
- **Linux**: Ubuntu 20.04+ / CentOS 8+ / Debian 11+
- **macOS**: macOS Monterey 12.0+ (solo para desarrollo)
- **Docker Desktop**: Versión 4.0+ (se instala automáticamente)

### **Configuración de Red:**
- **IP Estática**: Recomendada para estabilidad
- **Puertos**: 3000 (HTTP), 5432 (PostgreSQL interno)
- **Firewall**: Puerto 3000 abierto para clientes
- **DNS**: Configuración opcional para nombre de dominio local

---

## 🏗️ **INSTALACIÓN PRIMERA VEZ**

### **Paso 1: Preparación del Sistema**

#### **Windows:**
```batch
# 1. Crear directorio de instalación
mkdir C:\ACMA
cd C:\ACMA

# 2. Copiar archivos del proyecto
# Copiar toda la carpeta 'docker' aquí

# 3. Abrir PowerShell/CMD como Administrador
cd C:\ACMA\docker
```

#### **Linux:**
```bash
# 1. Crear directorio de instalación
sudo mkdir -p /opt/acma
sudo chown $USER:$USER /opt/acma
cd /opt/acma

# 2. Copiar archivos del proyecto
# Copiar toda la carpeta 'docker' aquí

# 3. Dar permisos de ejecución
chmod +x /opt/acma/docker/*.sh
```

### **Paso 2: Instalación Automática (Recomendada)**

#### **Windows:**
```batch
# Ejecutar como Administrador
cd C:\ACMA\docker
install-server.bat

# Seguir las instrucciones en pantalla
```

#### **Linux:**
```bash
# Ejecutar con sudo
cd /opt/acma/docker
sudo ./install-server.sh

# Seguir las instrucciones en pantalla
```

### **Paso 3: Configuración Inicial**

#### **Configurar IP del Servidor:**
```batch
# Windows
cd C:\ACMA\docker
configurar-postgres.bat

# Linux
cd /opt/acma/docker
nano .env  # Editar manualmente
```

**Variables importantes en .env:**
```bash
# IP del servidor (CAMBIAR POR LA IP REAL)
RAILS_HOST=192.168.68.69
RAILS_PORT=3000

# Configuración de base de datos
POSTGRES_DB=acma_production
POSTGRES_USER=postgres
POSTGRES_PASSWORD=Acma2024!Secure

# URL completa de conexión
DATABASE_URL=postgresql://postgres:Acma2024!Secure@db:5432/acma_production
```

### **Paso 4: Primera Ejecución**

#### **Windows:**
```batch
cd C:\ACMA\docker
start-server.bat
```

#### **Linux:**
```bash
cd /opt/acma/docker
./start-server.sh
```

**⏱️ Tiempo estimado primera ejecución:** 10-15 minutos

**Proceso automático:**
1. Docker descarga imágenes (PostgreSQL 15, Ruby/Rails)
2. PostgreSQL se inicializa y configura
3. Rails crea la base de datos
4. Se ejecutan migraciones
5. Servidor queda disponible en http://IP:3000

### **Paso 5: Verificación**

```bash
# Verificar servicios corriendo
docker compose ps

# Verificar conectividad
curl http://localhost:3000
# O abrir navegador: http://IP_SERVIDOR:3000

# Verificar base de datos
docker compose exec db psql -U postgres -l
```

---

## ⚙️ **CONFIGURACIÓN DEL SISTEMA**

### **Estructura de Archivos:**

```
C:\ACMA\docker\  (Windows) o /opt/acma/docker/ (Linux)
├── 📁 postgres_data/              ← ⭐ DATOS PERSISTENTES DB
├── 📁 backups/                    ← 💾 Backups automáticos
├── 📁 Aberturas/                  ← 🚀 Código de la aplicación
├── 📁 init-scripts/               ← 🔧 Scripts de inicialización DB
├── 📄 .env                        ← ⚙️ Variables de entorno
├── 📄 docker-compose.yml          ← 🐳 Configuración Docker
├── 📄 start-server.bat/.sh        ← 🏃 Script de inicio
├── 📄 backup-database.bat/.sh     ← 💾 Script de backup
├── 📄 restore-database.bat/.sh    ← 🔄 Script de restauración
├── 📄 configurar-postgres.bat     ← ⚙️ Configurador (Windows)
└── 📄 README-*.md                 ← 📚 Documentación
```

### **Variables de Entorno (.env):**

```bash
# === CONFIGURACIÓN DE RED ===
RAILS_HOST=192.168.68.69          # IP del servidor
RAILS_PORT=3000                   # Puerto HTTP
RAILS_ENV=production              # Entorno de ejecución

# === CONFIGURACIÓN DE BASE DE DATOS ===
POSTGRES_DB=acma_production       # Nombre de la DB
POSTGRES_USER=postgres            # Usuario DB
POSTGRES_PASSWORD=Acma2024!Secure # Contraseña DB (CAMBIAR!)
DATABASE_URL=postgresql://postgres:Acma2024!Secure@db:5432/acma_production

# === CONFIGURACIÓN DE RAILS ===
RAILS_MASTER_KEY=your_key_here    # Clave maestra (generar nueva)
RAILS_MAX_THREADS=5               # Hilos de Rails
SOLID_QUEUE_IN_PUMA=true         # Jobs en proceso principal
```

### **Configuración de Docker Compose:**

El archivo `docker-compose.yml` define dos servicios:

```yaml
services:
  db:                              # Servicio PostgreSQL
    image: postgres:15
    environment: [variables .env]
    volumes:
      - ./postgres_data:/var/lib/postgresql/data    # PERSISTENCIA
      - ./init-scripts:/docker-entrypoint-initdb.d  # INIT SCRIPTS
    ports: ["5432:5432"]
    healthcheck: [verificación automática]
    restart: unless-stopped

  web:                             # Servicio Rails
    build: [Dockerfile personalizado]
    environment: [variables .env]
    volumes: [código y datos persistentes]
    ports: ["3000:3000"]
    depends_on: [espera a que DB esté saludable]
    restart: unless-stopped
```

---

## 🛠️ **SCRIPTS Y HERRAMIENTAS**

### **Scripts de Inicio:**

#### **start-server.bat (Windows):**
```batch
# Funciones:
✅ Verifica Docker Desktop está corriendo
✅ Verifica Docker Compose disponible
✅ Inicia servicios en segundo plano (-d)
✅ Muestra estado de servicios
✅ Proporciona URLs de acceso
✅ Manejo de errores completo
```

#### **start-server.sh (Linux/Mac):**
```bash
# Funciones adicionales:
✅ Colorización de output
✅ Verificación de archivos requeridos
✅ Opciones para reinicio/verificación
✅ Información detallada del sistema
✅ Detección automática de IP
```

### **Scripts de Configuración:**

#### **configurar-postgres.bat (Windows):**
```batch
# Características:
✅ Interfaz interactiva fácil de usar
✅ Cambio de IP del servidor
✅ Cambio de puerto
✅ Cambio de contraseña DB
✅ Verificación de configuración
✅ Validación de formato de IP
```

#### **install-server.sh (Linux):**
```bash
# Instalación automática:
✅ Detecta distribución Linux
✅ Instala Docker automáticamente
✅ Configura permisos de usuario
✅ Crea estructura de directorios
✅ Descarga dependencias
```

### **Scripts de Backup:**

#### **backup-database.bat/.sh:**

**Tipo 1: Backup Completo**
```bash
# Incluye:
✅ SQL dump de toda la base de datos
✅ Archivos físicos de PostgreSQL
✅ Archivos de configuración (.env, docker-compose.yml)
✅ Metadatos y permisos

# Uso: Migración completa, restauración exacta
# Tiempo: 2-5 minutos
# Tamaño: ~50-500 MB dependiendo de datos
```

**Tipo 2: Solo SQL Dump**
```bash
# Incluye:
✅ Solo estructura y datos en formato SQL
✅ Compatible con cualquier PostgreSQL
✅ Tamaño optimizado

# Uso: Backup diario, migración de datos
# Tiempo: 30 segundos - 2 minutos
# Tamaño: ~1-50 MB dependiendo de datos
```

**Tipo 3: Solo Archivos**
```bash
# Incluye:
✅ Copia exacta de postgres_data/
✅ Configuraciones binarias
✅ Índices y optimizaciones

# Uso: Clonado exacto, máximo rendimiento
# Tiempo: 1-3 minutos
# Tamaño: ~50-500 MB
```

**Tipo 4: Backup Automático (Recomendado)**
```bash
# Incluye:
✅ SQL dump comprimido
✅ Configuraciones esenciales
✅ Compresión automática (tar.gz/zip)
✅ Optimizado para programación

# Uso: Backup automático diario/semanal
# Tiempo: 30 segundos - 1 minuto
# Tamaño: ~500 KB - 10 MB comprimido
```

### **Scripts de Restauración:**

#### **restore-database.bat/.sh:**

**Opciones de Restauración:**
1. **Desde SQL Dump** - Compatible, seguro, recomendado
2. **Desde Archivos Completos** - Restauración exacta, más rápido
3. **Listar Backups** - Ver detalles de backups disponibles

**Proceso de Restauración:**
```bash
# 1. Verificación de pre-requisitos
✅ Docker corriendo
✅ Backup válido disponible
✅ Confirmación del usuario

# 2. Backup de seguridad
✅ Respalda datos actuales antes de restaurar
✅ Permite rollback en caso de error

# 3. Restauración
✅ Para servicios necesarios
✅ Restaura datos
✅ Reinicia servicios
✅ Verifica integridad
```

---

## 🔄 **OPERACIÓN DIARIA**

### **Inicio del Servidor (Diario):**

#### **Windows:**
```batch
# Método 1: Manual
cd C:\ACMA\docker
start-server.bat

# Método 2: Automático (configurado)
# El sistema se inicia automáticamente al encender PC
```

#### **Linux:**
```bash
# Método 1: Manual
cd /opt/acma/docker
./start-server.sh

# Método 2: Servicio systemd
sudo systemctl start acma-server
sudo systemctl status acma-server
```

### **Verificación de Estado:**

```bash
# Estado de contenedores
docker compose ps

# Logs en tiempo real
docker compose logs -f

# Uso de recursos
docker stats

# Estado de la base de datos
docker compose exec db pg_isready -U postgres

# Verificar conectividad web
curl -I http://localhost:3000
```

### **Apagado del Servidor:**

```bash
# Apagado elegante
docker compose down

# Apagado de emergencia (fuerza)
docker compose down --remove-orphans

# Solo parar sin eliminar
docker compose stop
```

### **Comandos de Mantenimiento Diario:**

```bash
# Ver logs de errores
docker compose logs --tail=100 web | grep ERROR

# Limpiar logs antiguos
docker compose exec web sh -c "find /app/log -name '*.log' -exec truncate -s 0 {} \;"

# Verificar espacio en disco
df -h
du -sh /opt/acma/docker/postgres_data/

# Verificar memoria y CPU
docker stats --no-stream
```

---

## 💾 **SISTEMA DE BACKUPS**

### **Estrategia de Backup Recomendada:**

```bash
# DIARIO (Automático a las 2:00 AM)
Tipo: SQL Dump Comprimido (Tipo 4)
Retención: 7 días
Comando: echo "4" | ./backup-database.sh

# SEMANAL (Domingos a las 1:00 AM)
Tipo: Backup Completo (Tipo 1)
Retención: 4 semanas
Comando: echo "1" | ./backup-database.sh

# MENSUAL (Primer día del mes)
Tipo: Backup Completo + Copia externa
Retención: 12 meses
Acción: Copiar a USB/Nube
```

### **Configuración de Backup Automático:**

#### **Windows (Programador de Tareas):**
```batch
# Crear tarea para backup diario
schtasks /create /tn "ACMA Backup Diario" ^
  /tr "C:\ACMA\docker\backup-database.bat" ^
  /sc daily /st 02:00 /ru SYSTEM /rl HIGHEST

# Crear tarea para backup semanal
schtasks /create /tn "ACMA Backup Semanal" ^
  /tr "C:\ACMA\docker\backup-database.bat" ^
  /sc weekly /d SUN /st 01:00 /ru SYSTEM /rl HIGHEST
```

#### **Linux (Crontab):**
```bash
# Editar crontab
crontab -e

# Agregar tareas automáticas
0 2 * * * cd /opt/acma/docker && echo "4" | ./backup-database.sh >/dev/null 2>&1
0 1 * * 0 cd /opt/acma/docker && echo "1" | ./backup-database.sh >/dev/null 2>&1

# Limpiar backups antiguos (opcional)
0 3 * * * find /opt/acma/docker/backups/ -name "backup_acma_*" -mtime +30 -delete
```

### **Verificación de Backups:**

```bash
# Listar todos los backups
ls -lah backups/

# Verificar integridad de SQL dump
docker compose exec -T db psql -U postgres -d template1
  -c "\i backups/backup_acma_FECHA.sql" --set ON_ERROR_STOP=on

# Verificar tamaños
du -sh backups/*

# Probar restauración (EN ENTORNO DE PRUEBA)
echo -e "1
backup_acma_FECHA.sql
s" | ./restore-database.sh
```

### **Backup Manual de Emergencia:**

```bash
# Backup rápido antes de cambios importantes
echo "2" | ./backup-database.sh

# Backup completo antes de actualizaciones
echo "1" | ./backup-database.sh

# Backup solo de configuraciones
cp .env backup_config_$(date +%Y%m%d).env
cp docker-compose.yml backup_compose_$(date +%Y%m%d).yml
```

---

## 📊 **MONITOREO Y MANTENIMIENTO**

### **Monitoreo de Sistema:**

#### **Scripts de Monitoreo Automático:**

```bash
#!/bin/bash
# monitor-acma.sh - Script de monitoreo

# Verificar servicios
if ! docker compose ps | grep -q "Up"; then
    echo "ALERTA: Servicios no están corriendo" | mail -s "ACMA Alert" admin@empresa.com
fi

# Verificar espacio en disco
DISK_USAGE=$(df -h /opt/acma | awk 'NR==2{print $5}' | cut -d'%' -f1)
if [ $DISK_USAGE -gt 80 ]; then
    echo "ALERTA: Disco al ${DISK_USAGE}%" | mail -s "ACMA Disk Alert" admin@empresa.com
fi

# Verificar memoria
MEM_USAGE=$(free | awk 'NR==2{printf "%.2f%%", $3*100/$2}')
echo "Uso de memoria: $MEM_USAGE"

# Verificar base de datos
DB_SIZE=$(docker compose exec -T db psql -U postgres -d acma_production
  -c "SELECT pg_size_pretty(pg_database_size('acma_production'));" -t | tr -d ' ')
echo "Tamaño de DB: $DB_SIZE"
```

### **Métricas Importantes:**

```bash
# CPU y Memoria
docker stats --no-stream --format "table {{.Container}}	{{.CPUPerc}}	{{.MemUsage}}"

# Espacio en disco
df -h /opt/acma/docker/postgres_data/

# Conexiones a la DB
docker compose exec db psql -U postgres -d acma_production
  -c "SELECT count(*) as connections FROM pg_stat_activity;"

# Tamaño de tablas más grandes
docker compose exec db psql -U postgres -d acma_production
  -c "SELECT schemaname,tablename,pg_size_pretty(size) as size_pretty FROM (SELECT schemaname,tablename,pg_total_relation_size(schemaname||'.'||tablename) as size FROM (SELECT schemaname, tablename FROM pg_tables WHERE schemaname NOT LIKE 'pg_%' AND schemaname != 'information_schema') as tables ORDER BY size DESC LIMIT 10) as formatted;"
```

### **Mantenimiento Semanal:**

```bash
# Limpiar logs de Docker
docker system prune -f

# Optimizar base de datos
docker compose exec db psql -U postgres -d acma_production -c "VACUUM ANALYZE;"

# Actualizar estadísticas
docker compose exec db psql -U postgres -d acma_production -c "ANALYZE;"

# Verificar índices
docker compose exec db psql -U postgres -d acma_production
  -c "SELECT schemaname, tablename, attname, n_distinct, correlation FROM pg_stats WHERE schemaname = 'public';"
```

### **Mantenimiento Mensual:**

```bash
# Reindexar base de datos
docker compose exec db psql -U postgres -d acma_production -c "REINDEX DATABASE acma_production;"

# Actualizar imágenes de Docker
docker compose pull
docker compose up -d

# Rotar logs de aplicación
docker compose exec web logrotate /etc/logrotate.conf

# Verificar integridad de archivos
find /opt/acma/docker/postgres_data -type f -exec md5sum {} \; > integrity_check.md5
```

---

## 🚨 **SOLUCIÓN DE PROBLEMAS**

### **Problemas Comunes y Soluciones:**

#### **1. "No se puede conectar desde las aplicaciones cliente"**

**Diagnóstico:**
```bash
# Verificar que el servidor está corriendo
docker compose ps

# Verificar puerto abierto
netstat -tlnp | grep 3000

# Verificar firewall
# Windows: Windows Defender Firewall
# Linux: ufw status
```

**Soluciones:**
```bash
# 1. Verificar IP en .env
cat .env | grep RAILS_HOST

# 2. Abrir puerto en firewall
# Windows: netsh advfirewall firewall add rule name="ACMA" dir=in action=allow protocol=TCP localport=3000
# Linux: sudo ufw allow 3000

# 3. Reiniciar servicios
docker compose restart web

# 4. Verificar desde otro equipo
curl -I http://IP_SERVIDOR:3000
```

#### **2. "Error de base de datos / Connection refused"**

**Diagnóstico:**
```bash
# Verificar estado de PostgreSQL
docker compose logs db

# Verificar conectividad interna
docker compose exec web psql -U postgres -h db -d acma_production -c "SELECT 1;"
```

**Soluciones:**
```bash
# 1. Reiniciar solo la base de datos
docker compose restart db
sleep 10

# 2. Verificar variables de entorno
docker compose exec web env | grep DATABASE

# 3. Recrear base de datos (ÚLTIMO RECURSO)
docker compose down
docker volume rm docker_postgres_data
docker compose up -d
```

#### **3. "Servidor muy lento / Timeout"**

**Diagnóstico:**
```bash
# Verificar recursos
docker stats
free -h
df -h

# Verificar logs de errores
docker compose logs web | grep -i error
```

**Soluciones:**
```bash
# 1. Aumentar recursos de Docker
# Docker Desktop → Settings → Resources
# RAM: 6-8 GB, CPU: 4 cores

# 2. Optimizar base de datos
docker compose exec db psql -U postgres -d acma_production -c "VACUUM FULL;"

# 3. Limpiar logs
docker compose exec web sh -c "find /app/log -name '*.log' -exec truncate -s 0 {} \;"

# 4. Reiniciar servicios
docker compose restart
```

#### **4. "Docker no inicia / Error de permisos"**

**Windows:**
```batch
# Verificar Hyper-V habilitado
dism.exe /Online /Enable-Feature:Microsoft-Hyper-V /All /Restart

# Reiniciar Docker Desktop
net stop com.docker.service
net start com.docker.service
```

**Linux:**
```bash
# Agregar usuario a grupo docker
sudo usermod -aG docker $USER
newgrp docker

# Reiniciar servicio Docker
sudo systemctl restart docker
```

#### **5. "Espacio en disco insuficiente"**

```bash
# Limpiar imágenes no usadas
docker system prune -a -f

# Limpiar volúmenes huérfanos
docker volume prune -f

# Mover postgres_data a otro disco
docker compose down
mv postgres_data /path/to/larger/disk/
ln -s /path/to/larger/disk/postgres_data postgres_data
docker compose up -d
```

### **Logs y Debugging:**

```bash
# Ver todos los logs
docker compose logs

# Logs de un servicio específico
docker compose logs web
docker compose logs db

# Logs en tiempo real
docker compose logs -f --tail=100

# Logs de errores únicamente
docker compose logs web 2>&1 | grep -i error

# Acceder al contenedor para debugging
docker compose exec web bash
docker compose exec db psql -U postgres -d acma_production
```

---

## 🔐 **SEGURIDAD**

### **Configuración de Seguridad Básica:**

#### **1. Cambiar Contraseñas por Defecto:**

```bash
# Generar contraseña segura
NUEVA_PASSWORD=$(openssl rand -base64 32)

# Actualizar .env
sed -i "s/POSTGRES_PASSWORD=.*/POSTGRES_PASSWORD=${NUEVA_PASSWORD}/" .env
sed -i "s/postgresql:\/\/postgres:.*@/postgresql:\/\/postgres:${NUEVA_PASSWORD}@/" .env

# Regenerar clave maestra de Rails
NUEVA_KEY=$(docker compose exec web rails secret)
sed -i "s/RAILS_MASTER_KEY=.*/RAILS_MASTER_KEY=${NUEVA_KEY}/" .env

# Reiniciar servicios
docker compose down
docker compose up -d
```

#### **2. Configuración de Firewall:**

```bash
# Windows (PowerShell como Admin)
New-NetFirewallRule -DisplayName "ACMA Server" -Direction Inbound -Protocol TCP -LocalPort 3000 -Action Allow

# Linux (UFW)
sudo ufw allow from 192.168.0.0/16 to any port 3000
sudo ufw deny 5432  # Bloquear PostgreSQL externo
sudo ufw enable
```

#### **3. Acceso Restringido:**

```yaml
# En docker-compose.yml, remover exposición de puerto DB
services:
  db:
    # ports:
    #   - "5432:5432"  # COMENTAR ESTA LÍNEA
```

#### **4. Backup Cifrado:**

```bash
# Crear backup cifrado
echo "4" | ./backup-database.sh
gpg --symmetric --cipher-algo AES256 backups/backup_acma_$(date +%Y%m%d).tar.gz

# Desencriptar
gpg --decrypt backup_acma_$(date +%Y%m%d).tar.gz.gpg > backup_restaurar.tar.gz
```

### **Monitoreo de Seguridad:**

```bash
# Verificar conexiones activas
docker compose exec db psql -U postgres -d acma_production
  -c "SELECT usename, application_name, client_addr, state FROM pg_stat_activity WHERE state = 'active';"

# Ver intentos de conexión
docker compose logs db | grep "connection"

# Verificar usuarios de sistema
docker compose exec web cat /etc/passwd

# Verificar puertos abiertos
docker compose exec web netstat -tlnp
```

---

## 🔄 **FUTURAS ACTUALIZACIONES**

### **Preparación para Actualizaciones:**

#### **Antes de Actualizar:**

```bash
# 1. Backup completo
echo "1" | ./backup-database.sh

# 2. Documentar versión actual
docker compose images > version_actual.txt
docker compose exec web rails version >> version_actual.txt

# 3. Exportar configuraciones
cp .env .env.backup
cp docker-compose.yml docker-compose.yml.backup

# 4. Verificar compatibilidad
# - Revisar CHANGELOG del proyecto
# - Verificar requisitos nuevos
# - Probar en entorno de desarrollo
```

#### **Proceso de Actualización:**

```bash
# 1. Parar servicios
docker compose down

# 2. Hacer backup de código actual
cp -r Aberturas Aberturas_backup_$(date +%Y%m%d)

# 3. Actualizar archivos del proyecto
# - Reemplazar carpeta Aberturas/
# - Actualizar docker-compose.yml si es necesario
# - Revisar cambios en .env

# 4. Actualizar imágenes base
docker compose pull

# 5. Reconstruir contenedores
docker compose build --no-cache

# 6. Iniciar servicios
docker compose up -d

# 7. Ejecutar migraciones si es necesario
docker compose exec web rails db:migrate

# 8. Verificar funcionamiento
curl -I http://localhost:3000
```

#### **Rollback en Caso de Error:**

```bash
# 1. Parar servicios nuevos
docker compose down

# 2. Restaurar código anterior
rm -rf Aberturas
mv Aberturas_backup_$(date +%Y%m%d) Aberturas

# 3. Restaurar configuraciones
mv .env.backup .env
mv docker-compose.yml.backup docker-compose.yml

# 4. Restaurar base de datos
./restore-database.sh
# Seleccionar backup anterior a la actualización

# 5. Reiniciar servicios
docker compose up -d
```

### **Versionado y Control de Cambios:**

```bash
# Crear log de cambios
echo "$(date): Actualización a versión X.X.X" >> CHANGELOG.txt
echo "- Cambios realizados:" >> CHANGELOG.txt
echo "- Archivos modificados:" >> CHANGELOG.txt

# Mantener histórico de versiones
mkdir -p versiones/v$(date +%Y%m%d)
cp -r Aberturas versiones/v$(date +%Y%m%d)/
```

### **Checklist de Actualización:**

```markdown
### Pre-actualización:
- [ ] Backup completo realizado
- [ ] Documentación de versión actual
- [ ] Configuraciones respaldadas
- [ ] Entorno de prueba validado
- [ ] Ventana de mantenimiento programada

### Durante actualización:
- [ ] Servicios detenidos correctamente
- [ ] Archivos actualizados
- [ ] Imágenes Docker actualizadas
- [ ] Migraciones ejecutadas
- [ ] Servicios reiniciados

### Post-actualización:
- [ ] Conectividad verificada
- [ ] Aplicaciones cliente probadas
- [ ] Logs revisados sin errores
- [ ] Rendimiento verificado
- [ ] Backup post-actualización realizado
```

---

## 📋 **CHECKLIST COMPLETO**

### **Instalación Inicial:**

```markdown
#### Preparación:
- [ ] Hardware cumple requisitos mínimos
- [ ] Sistema operativo compatible
- [ ] Conexión a internet estable
- [ ] Permisos de administrador
- [ ] IP estática configurada (recomendado)

#### Instalación:
- [ ] Docker Desktop instalado y funcionando
- [ ] Archivos del proyecto copiados a ubicación final
- [ ] Scripts con permisos de ejecución (Linux)
- [ ] Variables de entorno configuradas (.env)
- [ ] IP del servidor configurada correctamente
- [ ] Firewall configurado (puerto 3000 abierto)

#### Primera Ejecución:
- [ ] start-server ejecutado exitosamente
- [ ] Servicios Docker corriendo (docker compose ps)
- [ ] Base de datos inicializada correctamente
- [ ] Servidor accesible desde navegador local
- [ ] Servidor accesible desde otra PC de la red

#### Configuración Inicial:
- [ ] Contraseñas por defecto cambiadas
- [ ] Backup inicial creado
- [ ] Monitoreo básico configurado
- [ ] Documentación entregada al cliente
```

### **Configuración de Producción:**

```markdown
#### Seguridad:
- [ ] Contraseñas seguras configuradas
- [ ] Puerto PostgreSQL no expuesto externamente
- [ ] Firewall configurado apropiadamente
- [ ] Acceso restringido por IP (opcional)
- [ ] Backup cifrado configurado (opcional)

#### Rendimiento:
- [ ] Recursos de Docker optimizados
- [ ] Base de datos optimizada (VACUUM, ANALYZE)
- [ ] Logs rotados y limitados
- [ ] Monitoreo de recursos configurado

#### Backup y Recuperación:
- [ ] Estrategia de backup definida
- [ ] Backup automático programado
- [ ] Procedimiento de restauración probado
- [ ] Backup externo configurado (USB/Nube)
- [ ] Retención de backups configurada
```

### **Operación Diaria:**

```markdown
#### Inicio del Día:
- [ ] Servidor iniciado (manual o automático)
- [ ] Estado de servicios verificado
- [ ] Logs revisados para errores
- [ ] Conectividad desde clientes verificada

#### Durante el Día:
- [ ] Monitoreo de recursos (CPU, RAM, Disco)
- [ ] Verificación de logs de errores
- [ ] Respaldo de datos críticos (si es necesario)

#### Fin del Día:
- [ ] Backup diario verificado
- [ ] Logs de errores revisados
- [ ] Estado del sistema documentado
- [ ] Apagado del servidor (opcional)
```

### **Mantenimiento Semanal:**

```markdown
- [ ] Backup completo realizado
- [ ] Base de datos optimizada (VACUUM ANALYZE)
- [ ] Logs antiguos limpiados
- [ ] Espacio en disco verificado
- [ ] Rendimiento del sistema revisado
- [ ] Actualizaciones de seguridad aplicadas
- [ ] Integridad de backups verificada
```

### **Mantenimiento Mensual:**

```markdown
- [ ] Backup completo copiado a ubicación externa
- [ ] Base de datos reindexada
- [ ] Imágenes Docker actualizadas
- [ ] Configuraciones respaldadas
- [ ] Documentación actualizada
- [ ] Procedimientos de emergencia probados
- [ ] Capacitación del personal (si es necesario)
```

---

## 📞 **SOPORTE Y CONTACTO**

### **Información de Emergencia:**

```markdown
#### Contactos:
- **Desarrollador Principal**: [Tu información]
- **Soporte Técnico**: [Información de contacto]
- **Emergencias**: [Teléfono 24/7]

#### Información del Sistema:
- **Versión ACMA**: [Versión actual]
- **Versión Docker**: docker --version
- **Ubicación Datos**: /opt/acma/docker/postgres_data/
- **Ubicación Backups**: /opt/acma/docker/backups/
- **Puerto Servidor**: 3000
- **Usuario DB**: postgres
```

### **Comandos de Emergencia:**

```bash
# Reinicio completo del sistema
docker compose down && docker compose up -d

# Verificación rápida de estado
docker compose ps && curl -I http://localhost:3000

# Backup de emergencia
echo "4" | ./backup-database.sh

# Logs de errores recientes
docker compose logs --tail=50 | grep -i error
```

---

**📝 Última actualización**: $(date)
**📧 Soporte**: [tu-email@empresa.com]
**🌐 Documentación**: [URL del repositorio]

---

> **⚠️ Importante**: Mantén este documento actualizado con cada cambio en el sistema. Es tu guía definitiva para administrar el servidor ACMA.