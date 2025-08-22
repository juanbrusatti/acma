# 💾 Scripts de Backup y Restauración de Base de Datos

## 📁 **ARCHIVOS INCLUIDOS**

### Scripts de Backup:
- **`backup-database.bat`** - Backup para Windows
- **`backup-database.sh`** - Backup para Linux/Mac

### Scripts de Restauración:
- **`restore-database.bat`** - Restauración para Windows
- **`restore-database.sh`** - Restauración para Linux/Mac

## 🚀 **CÓMO USAR LOS SCRIPTS DE BACKUP**

### **Windows:**
```batch
cd C:\ACMA\docker
backup-database.bat
```

### **Linux/Mac:**
```bash
cd /opt/acma/docker
./backup-database.sh
```

## 📋 **TIPOS DE BACKUP DISPONIBLES**

### **1. Backup Completo**
- ✅ SQL dump de la base de datos
- ✅ Archivos físicos de PostgreSQL
- ✅ Archivos de configuración
- **Uso**: Backup completo para migración

### **2. Solo SQL Dump**
- ✅ Solo los datos en formato SQL
- **Uso**: Backup rápido diario
- **Ventaja**: Más rápido, menor espacio

### **3. Solo Archivos**
- ✅ Copia física de postgres_data/
- **Uso**: Backup binario completo
- **Ventaja**: Restauración exacta

### **4. Backup Automático (Recomendado)**
- ✅ SQL dump comprimido
- ✅ Archivos de configuración
- **Uso**: Backup automático programado

## 📁 **ESTRUCTURA DE BACKUPS**

Después de ejecutar los backups, tendrás:

```
docker/
├── backups/
│   ├── backup_acma_20250822_143052.sql          ← SQL dump
│   ├── backup_acma_20250822_143052_data/        ← Archivos PostgreSQL
│   ├── backup_acma_20250822_143052_config.env   ← Configuración
│   ├── backup_acma_20250822_143052.zip          ← Backup comprimido
│   └── backup_acma_20250822_143052.tar.gz       ← Backup comprimido (Linux)
```

## 🔄 **CÓMO RESTAURAR BACKUPS**

### **Windows:**
```batch
cd C:\ACMA\docker
restore-database.bat
```

### **Linux/Mac:**
```bash
cd /opt/acma/docker
./restore-database.sh
```

### **Restauración Manual (Emergencia):**

**Desde SQL dump:**
```bash
# Parar servicios
docker compose down

# Iniciar solo la base de datos
docker compose up -d db

# Esperar que PostgreSQL esté listo
sleep 10

# Restaurar
docker compose exec -T db psql -U postgres -d acma_production < backups/backup_acma_FECHA.sql

# Iniciar todos los servicios
docker compose up -d
```

**Desde archivos completos:**
```bash
# Parar todo
docker compose down

# Respaldar datos actuales
mv postgres_data postgres_data_old

# Restaurar backup
cp -r backups/backup_acma_FECHA_data postgres_data

# Iniciar servicios
docker compose up -d
```

## ⏰ **AUTOMATIZACIÓN DE BACKUPS**

### **Windows (Programador de Tareas):**

1. **Abrir Programador de Tareas**
2. **Crear Tarea Básica**:
   - Nombre: `ACMA Backup Diario`
   - Desencadenador: `Diariamente a las 2:00 AM`
   - Acción: `C:\ACMA\docker\backup-database.bat`

### **Linux (Crontab):**

```bash
# Editar crontab
crontab -e

# Agregar línea para backup diario a las 2:00 AM
0 2 * * * cd /opt/acma/docker && ./backup-database.sh
```

### **Script de Backup Automático (Windows):**

```batch
@echo off
title Backup Automatico ACMA
cd C:\ACMA\docker

:: Ejecutar backup automático (opción 4)
echo 4 | backup-database.bat

:: Limpiar backups antiguos (más de 30 días)
forfiles /p backups /s /m backup_acma_*.* /d -30 /c "cmd /c del @path" 2>nul

echo Backup automatico completado
```

## 🧹 **LIMPIEZA DE BACKUPS ANTIGUOS**

### **Windows:**
```batch
# Eliminar backups más antiguos de 30 días
forfiles /p backups /s /m backup_acma_*.* /d -30 /c "cmd /c del @path"
```

### **Linux:**
```bash
# Eliminar backups más antiguos de 30 días
find backups/ -name "backup_acma_*" -mtime +30 -delete
```

## 📊 **VERIFICACIÓN DE BACKUPS**

### **Verificar integridad de SQL dump:**
```bash
# Verificar que el archivo SQL no está corrupto
docker compose exec -T db psql -U postgres -d template1 -c "\i backups/backup_acma_FECHA.sql" --set ON_ERROR_STOP=on
```

### **Verificar tamaño de backups:**
```bash
# Ver tamaños de todos los backups
du -sh backups/*
```

## 🚨 **RECUPERACIÓN DE EMERGENCIA**

### **Si se corrompe la base de datos:**

1. **Parar servicios:**
   ```bash
   docker compose down
   ```

2. **Mover datos corruptos:**
   ```bash
   mv postgres_data postgres_data_corrupted
   ```

3. **Restaurar último backup:**
   ```bash
   # Desde archivos
   cp -r backups/backup_acma_ULTIMO_data postgres_data

   # O desde SQL dump
   mkdir postgres_data
   docker compose up -d db
   sleep 10
   docker compose exec -T db psql -U postgres -d acma_production < backups/backup_acma_ULTIMO.sql
   ```

4. **Iniciar servicios:**
   ```bash
   docker compose up -d
   ```

## 📋 **CHECKLIST DE BACKUP**

### **Diario:**
- [ ] Verificar que el backup automático se ejecutó
- [ ] Comprobar que hay espacio en disco suficiente

### **Semanal:**
- [ ] Ejecutar backup completo manual
- [ ] Verificar integridad de un backup aleatorio
- [ ] Limpiar backups antiguos

### **Mensual:**
- [ ] Probar proceso de restauración completo
- [ ] Hacer backup a ubicación externa (USB, nube)
- [ ] Documentar cambios en procedimientos

## 💡 **CONSEJOS IMPORTANTES**

1. **Siempre probar la restauración** antes de necesitarla
2. **Mantener múltiples copias** en diferentes ubicaciones
3. **Documentar los procedimientos** para emergencias
4. **Monitorear el espacio en disco** para backups
5. **Programar backups en horarios de poco uso**

## 🔗 **COMANDOS RÁPIDOS**

```bash
# Backup rápido (solo datos)
echo "2" | ./backup-database.sh

# Ver últimos backups
ls -lt backups/ | head -5

# Tamaño total de backups
du -sh backups/

# Verificar base de datos actual
docker compose exec db psql -U postgres -d acma_production -c "SELECT pg_size_pretty(pg_database_size('acma_production'));"
```
