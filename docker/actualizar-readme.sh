#!/bin/bash

# Actualizar README principal con documentacion completa del servidor
cat > /home/bash/Desktop/DLAY/AR-Aberturas/acma/README.md << 'EOF'
# ACMA - Sistema de Aberturas

## 🏢 Descripción del Sistema

ACMA es un sistema completo de gestión para fabricación de aberturas que incluye:

- **Servidor Web**: Aplicación Ruby on Rails con base de datos PostgreSQL
- **Aplicación de Escritorio**: Cliente Electron para PCs de taller
- **Sistema Distribuido**: Un servidor central con múltiples clientes conectados

## 🖥️ Arquitectura del Sistema

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   PC TALLER 1   │    │   PC TALLER 2   │    │   PC TALLER N   │
│                 │    │                 │    │                 │
│  Electron App   │    │  Electron App   │    │  Electron App   │
│                 │    │                 │    │                 │
└─────────┬───────┘    └─────────┬───────┘    └─────────┬───────┘
          │                      │                      │
          │              CONEXIÓN DE RED                 │
          │             (192.168.68.69:3000)            │
          │                      │                      │
          └──────────────────────┼──────────────────────┘
                                 │
                    ┌─────────────▼──────────────┐
                    │      SERVIDOR CENTRAL      │
                    │                            │
                    │  ┌─────────────────────┐   │
                    │  │   Rails Server      │   │
                    │  │   (Puerto 3000)     │   │
                    │  └─────────────────────┘   │
                    │                            │
                    │  ┌─────────────────────┐   │
                    │  │   PostgreSQL DB     │   │
                    │  │   (Docker Volume)   │   │
                    │  └─────────────────────┘   │
                    │                            │
                    │  📁 Backups Automáticos    │
                    │  🔄 Inicio Automático      │
                    └────────────────────────────┘
```

## 📋 Requisitos del Sistema

### Servidor Central (Windows)
- **OS**: Windows 10/11 Professional o superior
- **RAM**: Mínimo 8 GB (16 GB recomendado)
- **Disco**: Mínimo 20 GB libres
- **Red**: IP fija recomendada
- **Software**: Docker Desktop

### PCs de Taller
- **OS**: Windows 10/11
- **RAM**: Mínimo 4 GB
- **Disco**: Mínimo 2 GB libres
- **Red**: Acceso al servidor (misma red)

## 🚀 Instalación Rápida

### Paso 1: Preparar el Servidor

1. **Descargar ACMA**:
   ```bash
   git clone [URL_REPO]
   cd acma
   ```

2. **Ejecutar Instalador Automático**:
   ```bash
   cd docker
   install-server-windows.bat
   ```

3. **Configurar Inicio Automático**:
   ```bash
   auto-start-setup.bat
   ```

4. **Configurar Backups Automáticos**:
   ```bash
   backup-scheduler.bat
   ```

### Paso 2: Instalar en PCs de Taller

1. Ir a la carpeta `electron-app`
2. Ejecutar `ACMA-Setup.exe`
3. Configurar IP del servidor: `192.168.68.69`

## 📁 Estructura del Proyecto

```
acma/
├── 📄 README.md                    # Este archivo
├── 🐳 docker/                      # Configuración del servidor
│   ├── docker-compose.yml          # Orquestación de contenedores
│   ├── .env                        # Variables de configuración
│   ├── start-server.bat            # Iniciar servidor
│   ├── stop-server.bat             # Detener servidor
│   ├── backup-database.bat         # Crear backup manual
│   ├── restore-database.bat        # Restaurar backup
│   ├── install-server-windows.bat  # Instalador automático
│   ├── auto-start-setup.bat        # Configurar inicio automático
│   ├── backup-scheduler.bat        # Configurar backups automáticos
│   ├── verificar-servidor.bat      # Diagnóstico completo
│   └── README-SERVIDOR-WINDOWS.md  # Documentación técnica
├── 🚢 Aberturas/                   # Aplicación Rails
│   ├── app/                        # Código de la aplicación
│   ├── config/                     # Configuraciones
│   ├── db/                         # Base de datos y migraciones
│   └── Dockerfile                  # Imagen de la aplicación
├── 💻 electron-app/                # Aplicación de escritorio
│   ├── main.js                     # Aplicación principal
│   ├── package.json                # Dependencias
│   └── DELIVER-FILES/              # Archivos para distribución
└── 📊 backups/                     # Backups automáticos (se crea automáticamente)
```

## 🔧 Comandos Principales

### Servidor

```bash
# Iniciar servidor
start-server.bat

# Detener servidor
stop-server.bat

# Ver estado
docker compose ps

# Ver logs en tiempo real
docker compose logs -f

# Verificar sistema completo
verificar-servidor.bat

# Crear backup
backup-database.bat

# Restaurar backup
restore-database.bat
```

### Desarrollo

```bash
# Entrar al contenedor de Rails
docker compose exec web bash

# Ejecutar migraciones
docker compose exec web bundle exec rails db:migrate

# Acceder a consola Rails
docker compose exec web bundle exec rails console

# Acceder a PostgreSQL
docker compose exec db psql -U acma_user -d acma_production
```

## 🌐 Acceso al Sistema

### URLs de Acceso

- **Local**: http://localhost:3000
- **Red**: http://192.168.68.69:3000
- **Desde PCs Taller**: http://[IP_SERVIDOR]:3000

### Puertos Utilizados

- **3000**: Aplicación Rails (HTTP)
- **5432**: PostgreSQL (interno de Docker)

## 💾 Sistema de Backups

### Backups Automáticos

El sistema crea backups automáticamente:

- **Diario**: 2:00 AM (última semana)
- **Semanal**: Domingos 3:00 AM (último mes)
- **Mensual**: Día 1 de cada mes 4:00 AM (último año)
- **Completo**: Incluye archivos subidos

### Ubicación de Backups

```
docker/backups/
├── backup_acma_20240315_020000.sql.gz     # Backup diario
├── backup_acma_20240310_030000.sql.gz     # Backup semanal
├── files_backup_20240301_040000.tar.gz    # Backup de archivos
└── restore-backup.bat                     # Script de restauración
```

### Restaurar Backup

```bash
# Restaurar último backup
restore-database.bat

# Restaurar backup específico
restore-database.bat backup_acma_20240315_020000.sql.gz
```

## 🔐 Seguridad

### Base de Datos

- Usuario: `acma_user`
- Contraseña: Generada automáticamente en `.env`
- Acceso: Solo desde contenedores Docker

### Red

- Puerto 3000 abierto en firewall
- Acceso restringido a red local
- Sin exposición a internet

### Archivos

- Datos persistentes en volúmenes Docker
- Backups cifrados con gzip
- Permisos restringidos en archivos de configuración

## 🚨 Solución de Problemas

### Servidor No Inicia

1. **Verificar Docker**:
   ```bash
   docker --version
   docker info
   ```

2. **Verificar archivos**:
   ```bash
   verificar-servidor.bat
   ```

3. **Reiniciar servicios**:
   ```bash
   stop-server.bat
   start-server.bat
   ```

### Error de Conexión desde PCs

1. **Verificar IP del servidor**:
   ```bash
   ipconfig
   ```

2. **Verificar firewall**:
   ```bash
   netsh advfirewall firewall show rule name="ACMA Server"
   ```

3. **Verificar acceso**:
   ```bash
   telnet [IP_SERVIDOR] 3000
   ```

### Base de Datos Corrupta

1. **Detener servidor**:
   ```bash
   stop-server.bat
   ```

2. **Restaurar último backup**:
   ```bash
   restore-database.bat
   ```

3. **Reiniciar servidor**:
   ```bash
   start-server.bat
   ```

## 📞 Soporte Técnico

### Logs del Sistema

```bash
# Logs de la aplicación
docker compose logs web

# Logs de la base de datos
docker compose logs db

# Logs del sistema Windows
eventvwr.msc
```

### Información del Sistema

```bash
# Estado completo
verificar-servidor.bat

# Información de Docker
docker system info

# Uso de recursos
docker stats
```

### Monitoreo

- **Aplicación**: http://localhost:3000/health
- **Base de datos**: Verificación automática en `docker-compose.yml`
- **Disco**: Alertas automáticas si <5GB libres

## 🔄 Mantenimiento

### Diario

- ✅ Backups automáticos (2:00 AM)
- ✅ Verificación de salud de servicios
- ✅ Limpieza de logs antiguos

### Semanal

- 🔍 Revisar logs de errores
- 📊 Verificar uso de disco
- 🔄 Reinicio programado (opcional)

### Mensual

- 📁 Limpieza de backups antiguos
- 🔄 Actualización de dependencias
- 📋 Revisión de rendimiento

### Anual

- 🔐 Cambio de contraseñas
- 💿 Backup completo externo
- 📋 Revisión de seguridad

## 📋 Checklist de Instalación

### Pre-instalación

- [ ] Windows 10/11 Professional
- [ ] 8+ GB RAM disponible
- [ ] 20+ GB espacio en disco
- [ ] Conexión a internet estable
- [ ] Permisos de administrador

### Instalación

- [ ] Ejecutar `install-server-windows.bat`
- [ ] Verificar instalación de Docker
- [ ] Configurar IP fija (recomendado)
- [ ] Ejecutar `auto-start-setup.bat`
- [ ] Ejecutar `backup-scheduler.bat`
- [ ] Ejecutar `verificar-servidor.bat`

### Post-instalación

- [ ] Servidor accesible en http://localhost:3000
- [ ] Servidor accesible desde red
- [ ] Backups funcionando
- [ ] Inicio automático configurado
- [ ] Firewall configurado
- [ ] PCs de taller conectados

## 📖 Documentación Adicional

- **Técnica**: `docker/README-SERVIDOR-WINDOWS.md`
- **Manual de Usuario**: `electron-app/DELIVER-FILES/MANUAL-TECNICO.md`
- **Iconos**: `electron-app/DELIVER-FILES/ICONS-README.md`

## 🏷️ Versiones

- **ACMA**: v2.0
- **Rails**: 8.0.2
- **PostgreSQL**: 15
- **Docker**: 20.10+
- **Electron**: 13+

## 👥 Créditos

Desarrollado para gestión de fabricación de aberturas con arquitectura distribuida servidor-cliente.

---

**🎯 Objetivo**: Sistema robusto, automático y fácil de mantener para entornos de producción Windows.
EOF

echo "✅ README principal actualizado con documentación completa"
