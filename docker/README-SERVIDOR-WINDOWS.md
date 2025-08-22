# 🚀 GUÍA COMPLETA DEL SERVIDOR ACMA - WINDOWS

Esta es la guía definitiva para instalar, configurar y mantener el servidor ACMA con PostgreSQL en **Windows**. Incluye todo lo que necesitas saber desde la instalación inicial hasta el mantenimiento diario.

---

## 📖 **ÍNDICE**

1. [Requisitos Windows](#-requisitos-windows)
2. [Instalación Paso a Paso](#-instalación-paso-a-paso)
3. [Configuración Inicial](#-configuración-inicial)
4. [Scripts Windows Incluidos](#-scripts-windows-incluidos)
5. [Operación Diaria](#-operación-diaria)
6. [Sistema de Backups](#-sistema-de-backups)
7. [Automatización Windows](#-automatización-windows)
8. [Monitoreo y Mantenimiento](#-monitoreo-y-mantenimiento)
9. [Solución de Problemas Windows](#-solución-de-problemas-windows)
10. [Seguridad Windows](#-seguridad-windows)
11. [Futuras Actualizaciones](#-futuras-actualizaciones)
12. [Checklist de Implementación](#-checklist-de-implementación)

---

## 💻 **REQUISITOS WINDOWS**

### **Sistema Operativo Compatible:**
- ✅ **Windows 10 Pro** (versión 1903 o superior)
- ✅ **Windows 11 Pro/Enterprise** (recomendado)
- ✅ **Windows Server 2019/2022** (para empresas)
- ❌ Windows 10 Home (limitado para Docker)

### **Hardware Mínimo:**
- **RAM**: 8 GB (16 GB recomendado)
- **CPU**: Intel i5 8th gen o AMD Ryzen 5 (o superior)
- **Almacenamiento**: 50 GB libres en SSD
- **Red**: Tarjeta Ethernet Gigabit
- **Virtualización**: Hyper-V habilitado

### **Hardware Recomendado para Producción:**
- **RAM**: 16-32 GB
- **CPU**: Intel i7/i9 o AMD Ryzen 7/9
- **Almacenamiento**: SSD de 500 GB o más
- **Red**: Conexión cableada estable
- **UPS**: Sistema de alimentación ininterrumpida

### **Configuración de Red Windows:**
- **IP Estática**: Configurada en adaptador de red
- **Puerto 3000**: Abierto en Windows Firewall
- **Resolución DNS**: Configuración local opcional
- **Workgroup/Dominio**: Compatible con ambos

---

## 🛠️ **INSTALACIÓN PASO A PASO**

### **PASO 1: Preparar Windows**

1. **Verificar versión de Windows:**
   ```cmd
   winver
   ```

2. **Habilitar Hyper-V y Contenedores:**
   ```powershell
   # Ejecutar PowerShell como Administrador
   Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All
   Enable-WindowsOptionalFeature -Online -FeatureName Containers -All

   # Reiniciar cuando se solicite
   Restart-Computer
   ```

3. **Configurar IP estática (Recomendado):**
   - Panel de Control → Red e Internet → Centro de redes
   - Cambiar configuración del adaptador
   - Click derecho en adaptador → Propiedades
   - Protocolo de Internet versión 4 (TCP/IPv4)
   - Configurar IP estática (ej: 192.168.1.100)

### **PASO 2: Descargar e Instalar Docker Desktop**

1. **Descarga automática:**
   - Ejecutar el script `install-server-windows.bat` (incluido)
   - O manualmente desde: https://www.docker.com/products/docker-desktop/

2. **Instalación manual:**
   - Ejecutar `Docker Desktop Installer.exe`
   - Seguir el asistente de instalación
   - Seleccionar "Use WSL 2 instead of Hyper-V"
   - Reiniciar cuando se solicite

3. **Verificación:**
   ```cmd
   docker --version
   docker compose version
   ```

### **PASO 3: Preparar Archivos del Proyecto**

1. **Crear estructura de directorios:**
   ```cmd
   mkdir C:\ACMA
   cd C:\ACMA
   ```

2. **Copiar archivos del proyecto:**
   - Copiar toda la carpeta `docker` a `C:\ACMA\`
   - Estructura final:
   ```
   C:\ACMA\
   ├── docker\
   │   ├── start-server.bat
   │   ├── backup-database.bat
   │   ├── configurar-postgres.bat
   │   ├── docker-compose.yml
   │   ├── .env
   │   └── ...otros archivos
   ```

### **PASO 4: Configuración Inicial**

1. **Configurar IP del servidor:**
   ```cmd
   cd C:\ACMA\docker
   configurar-postgres.bat
   ```

2. **En el configurador:**
   - Opción 1: Cambiar IP del servidor
   - Ingresar la IP de la PC Windows (ej: 192.168.1.100)
   - Confirmar configuración

3. **Configurar Windows Firewall:**
   ```cmd
   # Abrir puerto 3000 en Firewall
   netsh advfirewall firewall add rule name="ACMA Server" dir=in action=allow protocol=TCP localport=3000
   ```

### **PASO 5: Primera Ejecución**

1. **Iniciar el servidor:**
   ```cmd
   cd C:\ACMA\docker
   start-server.bat
   ```

2. **Tiempo estimado primera vez:**
   - Descarga de imágenes: 5-10 minutos
   - Inicialización PostgreSQL: 2-3 minutos
   - Configuración Rails: 1-2 minutos
   - **Total: 10-15 minutos**

3. **Verificación:**
   - Abrir navegador: `http://localhost:3000`
   - Desde otra PC: `http://IP_SERVIDOR:3000`

---

## ⚙️ **CONFIGURACIÓN INICIAL**

### **Archivo .env - Variables de Entorno**

Ubicación: `C:\ACMA\docker\.env`

```ini
# Configuración de PostgreSQL
POSTGRES_DB=acma_production
POSTGRES_USER=postgres
POSTGRES_PASSWORD=Acma2024!Secure

# Configuración de Rails
DATABASE_URL=postgresql://postgres:Acma2024!Secure@db:5432/acma_production
RAILS_ENV=production
RAILS_MASTER_KEY=your_master_key_here

# Configuración de Red
RAILS_HOST=192.168.1.100    # ← CAMBIAR POR IP REAL
RAILS_PORT=3000
```

### **Configuración de Red Avanzada**

1. **IP Estática Detallada:**
   ```cmd
   # Ver configuración actual
   ipconfig /all

   # Configurar IP estática via comando
   netsh interface ip set address "Ethernet" static 192.168.1.100 255.255.255.0 192.168.1.1
   netsh interface ip set dns "Ethernet" static 8.8.8.8
   ```

2. **Configurar nombre de host (Opcional):**
   ```cmd
   # Cambiar nombre del equipo
   wmic computersystem where name="%computername%" call rename name="ACMA-SERVER"
   ```

### **Configuración de Docker Desktop**

1. **Abrir Docker Desktop**
2. **Settings → General:**
   - ✅ Start Docker Desktop when you log in
   - ✅ Use Docker Compose V2

3. **Settings → Resources:**
   - **Memory**: Mínimo 4 GB (8 GB recomendado)
   - **CPUs**: Mínimo 2 cores (4 recomendado)
   - **Disk Image Size**: Mínimo 60 GB

4. **Settings → Docker Engine:**
   ```json
   {
     "log-driver": "json-file",
     "log-opts": {
       "max-size": "10m",
       "max-file": "3"
     }
   }
   ```

---

## 📁 **SCRIPTS WINDOWS INCLUIDOS**

### **start-server.bat**
**Propósito**: Iniciar el servidor ACMA
```batch
# Uso:
cd C:\ACMA\docker
start-server.bat
```
**¿Qué hace?**
1. Verifica que Docker Desktop esté corriendo
2. Valida archivos de configuración
3. Inicia servicios en segundo plano
4. Muestra status de inicialización
5. Se puede cerrar la ventana al terminar

### **configurar-postgres.bat**
**Propósito**: Configurar IP, puertos y credenciales
```batch
# Uso:
configurar-postgres.bat
```
**Opciones disponibles:**
1. **Cambiar IP del servidor** (más común)
2. **Cambiar puerto** (si hay conflictos)
3. **Cambiar contraseña PostgreSQL** (seguridad)
4. **Cambiar nombre de BD** (personalización)
5. **Ver configuración actual**
6. **Resetear a valores por defecto**

### **backup-database.bat**
**Propósito**: Crear respaldos de la base de datos
```batch
# Uso:
backup-database.bat
```
**4 Tipos de backup:**
1. **Completo**: SQL + archivos + configuraciones
2. **Solo SQL**: Rápido, solo datos
3. **Solo archivos**: Copia binaria de PostgreSQL
4. **Automático**: Comprimido, ideal para programar

**Ubicación de backups**: `C:\ACMA\docker\backups\`

### **restore-database.bat**
**Propósito**: Restaurar respaldos
```batch
# Uso:
restore-database.bat
```
**Opciones:**
1. **Restaurar desde SQL** (recomendado)
2. **Restaurar archivos completos** (backup binario)
3. **Listar backups disponibles**

### **Scripts de Automatización (Adicionales)**

#### **auto-start-setup.bat**
**Propósito**: Configurar arranque automático
```batch
# Configura el servidor para iniciar con Windows
auto-start-setup.bat
```

#### **backup-scheduler.bat**
**Propósito**: Programar backups automáticos
```batch
# Programa backup diario a las 2:00 AM
backup-scheduler.bat
```

#### **verificar-servidor.bat**
**Propósito**: Verificar estado del sistema
```batch
# Verifica Docker, servicios y conectividad
verificar-servidor.bat
```

---

## 🔄 **OPERACIÓN DIARIA**

### **Encender el Servidor (Diario)**

1. **Método Automático** (Si está configurado):
   - El servidor se inicia automáticamente con Windows
   - Verificar en navegador: `http://IP_SERVIDOR:3000`

2. **Método Manual**:
   ```cmd
   cd C:\ACMA\docker
   start-server.bat
   ```

### **Verificar Estado del Servidor**

```cmd
# Ver servicios corriendo
docker compose ps

# Ver logs en tiempo real
docker compose logs -f

# Ver uso de recursos
docker stats
```

### **Apagar el Servidor (Final del día)**

```cmd
cd C:\ACMA\docker
docker compose down
```

### **Reiniciar Servicios (Si hay problemas)**

```cmd
cd C:\ACMA\docker
docker compose restart
```

---

## 💾 **SISTEMA DE BACKUPS**

### **Estrategia de Backups Recomendada**

1. **Diario**: Backup automático (SQL comprimido)
2. **Semanal**: Backup completo manual
3. **Mensual**: Copia a ubicación externa
4. **Antes de updates**: Backup completo

### **Configurar Backup Automático Diario**

1. **Ejecutar configurador:**
   ```cmd
   backup-scheduler.bat
   ```

2. **O configurar manualmente:**
   - Abrir "Programador de tareas" (`taskschd.msc`)
   - Crear tarea básica
   - **Nombre**: "ACMA Backup Diario"
   - **Desencadenador**: Diariamente a las 2:00 AM
   - **Programa**: `C:\ACMA\docker\backup-database.bat`
   - **Argumentos**: (dejar vacío, usará opción 4 automática)

### **Backup Manual Rápido**

```cmd
cd C:\ACMA\docker
backup-database.bat
# Seleccionar opción 4 (Automático)
```

### **Ubicaciones de Backup**

```
C:\ACMA\docker\backups\
├── backup_acma_20250822_080000.zip      ← Backup diario automático
├── backup_acma_20250822_140000.sql      ← Backup manual SQL
├── backup_acma_20250822_140000_data\    ← Backup completo
└── backup_acma_20250822_140000_config.env
```

### **Limpiar Backups Antiguos**

```cmd
# Eliminar backups de más de 30 días
forfiles /p C:\ACMA\docker\backups /s /m backup_acma_*.* /d -30 /c "cmd /c del @path"
```

### **Backup a Ubicación Externa**

```cmd
# Copiar a USB o red
xcopy C:\ACMA\docker\backups\* E:\ACMA_BACKUPS\ /s /e /y

# O comprimir todo
powershell Compress-Archive -Path "C:\ACMA\docker\backups\*" -DestinationPath "E:\ACMA_BACKUP_COMPLETO.zip"
```

---

## 🤖 **AUTOMATIZACIÓN WINDOWS**

### **Arranque Automático del Servidor**

#### **Método 1: Programador de Tareas (Recomendado)**

1. **Configuración automática:**
   ```cmd
   # Ejecutar como Administrador
   auto-start-setup.bat
   ```

2. **Configuración manual:**
   - `Win + R` → `taskschd.msc`
   - Crear tarea básica
   - **Nombre**: "ACMA Server Startup"
   - **Desencadenador**: "Al iniciar el equipo"
   - **Programa**: `C:\ACMA\docker\start-server.bat`
   - **Iniciar en**: `C:\ACMA\docker\`
   - ✅ Ejecutar con privilegios más altos
   - ✅ Ejecutar tanto si el usuario ha iniciado sesión como si no

#### **Método 2: Servicio Windows (Avanzado)**

```cmd
# Instalar NSSM (Non-Sucking Service Manager)
# Descargar desde: https://nssm.cc/download

# Instalar servicio
nssm install "ACMA Server" "C:\ACMA\docker\start-server.bat"
nssm set "ACMA Server" AppDirectory "C:\ACMA\docker"
nssm set "ACMA Server" DisplayName "Servidor ACMA"
nssm set "ACMA Server" Start SERVICE_AUTO_START

# Comandos de control
net start "ACMA Server"
net stop "ACMA Server"
```

### **Monitoreo Automático**

#### **Script de Monitoreo (monitoreo.bat)**

```batch
@echo off
title Monitor ACMA Server
:loop
cls
echo ================================
echo    MONITOR SERVIDOR ACMA
echo ================================
echo.
echo Estado de Docker:
docker info --format "{{.ServerVersion}}" 2>nul && echo [OK] Docker corriendo || echo [ERROR] Docker no disponible
echo.
echo Estado de servicios:
docker compose ps
echo.
echo Uso de recursos:
docker stats --no-stream
echo.
echo Conectividad:
curl -s http://localhost:3000 >nul && echo [OK] Servidor accesible || echo [ERROR] Servidor no responde
echo.
echo Ultima verificacion: %date% %time%
echo.
timeout /t 30 /nobreak
goto loop
```

### **Actualizaciones Automáticas**

#### **Script de Update (update-servidor.bat)**

```batch
@echo off
title Actualizacion ACMA Server
echo Creando backup pre-actualización...
backup-database.bat

echo Descargando actualizaciones...
docker compose pull

echo Aplicando actualizaciones...
docker compose down
docker compose up -d

echo Verificando actualización...
timeout /t 30
curl http://localhost:3000
echo Actualización completada
```

---

## 📊 **MONITOREO Y MANTENIMIENTO**

### **Verificaciones Diarias**

```cmd
# Script de verificación diaria
verificar-servidor.bat
```

**¿Qué verifica?**
1. ✅ Docker Desktop está corriendo
2. ✅ Servicios PostgreSQL y Rails activos
3. ✅ Puerto 3000 accesible
4. ✅ Espacio en disco suficiente (>5GB)
5. ✅ Memoria RAM disponible
6. ✅ Último backup exitoso

### **Logs del Sistema**

```cmd
# Ver logs de la aplicación
docker compose logs web

# Ver logs de PostgreSQL
docker compose logs db

# Ver logs con filtro de tiempo
docker compose logs --since "2024-08-22T10:00:00" web
```

### **Monitoreo de Recursos**

```cmd
# Uso de recursos en tiempo real
docker stats

# Espacio utilizado por Docker
docker system df

# Información detallada de contenedores
docker compose ps --all
```

### **Mantenimiento Semanal**

1. **Limpiar Docker:**
   ```cmd
   docker system prune -f
   docker image prune -a -f
   ```

2. **Verificar logs de errores:**
   ```cmd
   docker compose logs | findstr ERROR
   ```

3. **Backup completo:**
   ```cmd
   backup-database.bat
   # Seleccionar opción 1 (Completo)
   ```

4. **Verificar integridad de BD:**
   ```cmd
   docker compose exec db pg_dump --schema-only -U postgres acma_production > schema_check.sql
   ```

### **Monitoreo de Red**

```cmd
# Verificar conectividad externa
ping 8.8.8.8

# Verificar puertos abiertos
netstat -an | findstr :3000

# Verificar conexiones activas
netstat -an | findstr :3000 | findstr ESTABLISHED
```

---

## 🚨 **SOLUCIÓN DE PROBLEMAS WINDOWS**

### **Problema: Docker Desktop no inicia**

**Síntomas:**
- Error al ejecutar `docker --version`
- Docker Desktop muestra error en la bandeja

**Soluciones:**
1. **Verificar Hyper-V:**
   ```cmd
   bcdedit /enum | findstr hypervisorlaunchtype
   # Debe mostrar: hypervisorlaunchtype Auto
   ```

2. **Reiniciar servicio Docker:**
   ```cmd
   net stop com.docker.service
   net start com.docker.service
   ```

3. **Reinstalar Docker Desktop:**
   - Desinstalar Docker Desktop
   - Reiniciar Windows
   - Reinstalar desde: https://www.docker.com/products/docker-desktop/

### **Problema: Puerto 3000 ocupado**

**Síntomas:**
- Error "Port already in use"
- No se puede acceder al servidor

**Soluciones:**
1. **Identificar proceso:**
   ```cmd
   netstat -ano | findstr :3000
   tasklist /fi "pid eq [PID_ENCONTRADO]"
   ```

2. **Terminar proceso:**
   ```cmd
   taskkill /f /pid [PID_ENCONTRADO]
   ```

3. **Cambiar puerto en configuración:**
   ```cmd
   configurar-postgres.bat
   # Opción 2: Cambiar puerto
   ```

### **Problema: Base de datos corrupta**

**Síntomas:**
- Error de conexión a PostgreSQL
- Datos inconsistentes

**Soluciones:**
1. **Verificar logs:**
   ```cmd
   docker compose logs db
   ```

2. **Restaurar último backup:**
   ```cmd
   restore-database.bat
   # Opción 1: Restaurar desde SQL
   ```

3. **Recrear base de datos:**
   ```cmd
   docker compose down
   rmdir /s postgres_data
   docker compose up -d
   ```

### **Problema: Servidor muy lento**

**Síntomas:**
- Respuesta lenta de la aplicación
- Timeouts en clientes

**Soluciones:**
1. **Verificar recursos:**
   ```cmd
   docker stats
   # Ver uso de CPU y memoria
   ```

2. **Aumentar recursos Docker:**
   - Docker Desktop → Settings → Resources
   - Aumentar Memory a 8GB+
   - Aumentar CPUs a 4+

3. **Limpiar logs:**
   ```cmd
   docker compose down
   # Eliminar archivos de log grandes
   docker compose up -d
   ```

### **Problema: Firewall bloquea conexiones**

**Síntomas:**
- Funciona en `localhost` pero no desde otras PCs
- Error de conexión rechazada

**Soluciones:**
1. **Verificar regla de firewall:**
   ```cmd
   netsh advfirewall firewall show rule name="ACMA Server"
   ```

2. **Agregar regla si no existe:**
   ```cmd
   netsh advfirewall firewall add rule name="ACMA Server" dir=in action=allow protocol=TCP localport=3000
   ```

3. **Deshabilitar temporalmente firewall (solo para test):**
   ```cmd
   netsh advfirewall set allprofiles state off
   # RECORDAR VOLVER A ACTIVAR
   netsh advfirewall set allprofiles state on
   ```

### **Problema: Actualizaciones de Windows**

**Síntomas:**
- Servidor no inicia después de Windows Update
- Docker no funciona tras reinicio

**Soluciones:**
1. **Verificar Docker después de update:**
   ```cmd
   docker --version
   docker compose version
   ```

2. **Reconfigurar Docker si es necesario:**
   ```cmd
   # Reiniciar servicios Docker
   net stop com.docker.service
   net start com.docker.service
   ```

3. **Verificar configuración de red:**
   ```cmd
   ipconfig /all
   # Confirmar que IP estática se mantiene
   ```

---

## 🔒 **SEGURIDAD WINDOWS**

### **Configuración de Firewall**

```cmd
# Reglas específicas para ACMA
netsh advfirewall firewall add rule name="ACMA HTTP" dir=in action=allow protocol=TCP localport=3000
netsh advfirewall firewall add rule name="ACMA HTTP Out" dir=out action=allow protocol=TCP localport=3000

# Bloquear acceso PostgreSQL externo (seguridad)
netsh advfirewall firewall add rule name="Block PostgreSQL" dir=in action=block protocol=TCP localport=5432
```

### **Configuración de Usuarios Windows**

1. **Crear usuario específico para ACMA:**
   ```cmd
   net user acma-service SecurePassword123! /add
   net localgroup "Users" acma-service /add
   ```

2. **Configurar permisos en carpeta:**
   ```cmd
   icacls C:\ACMA /grant acma-service:(OI)(CI)F
   ```

### **Contraseñas Seguras**

1. **Cambiar contraseña por defecto:**
   ```cmd
   configurar-postgres.bat
   # Opción 3: Cambiar contraseña PostgreSQL
   ```

2. **Generar contraseña fuerte:**
   ```powershell
   # Generar contraseña de 16 caracteres
   -join ((33..126) | Get-Random -Count 16 | % {[char]$_})
   ```

### **Backups Seguros**

```cmd
# Cifrar backups (Windows 10 Pro/Enterprise)
cipher /e C:\ACMA\docker\backups

# Backup a ubicación cifrada
robocopy C:\ACMA\docker\backups E:\ACMA_SECURE_BACKUP /mir /sec
```

### **Monitoreo de Seguridad**

```cmd
# Ver conexiones activas
netstat -an | findstr :3000

# Ver logs de seguridad de Windows
eventvwr.msc
# Ir a: Registros de Windows > Seguridad
```

---

## 🔄 **FUTURAS ACTUALIZACIONES**

### **Procedimiento de Actualización**

1. **Preparación:**
   ```cmd
   # Backup completo pre-actualización
   backup-database.bat

   # Verificar espacio en disco
   dir C:\ | findstr bytes
   ```

2. **Descarga de actualizaciones:**
   ```cmd
   cd C:\ACMA\docker
   docker compose pull
   ```

3. **Aplicar actualización:**
   ```cmd
   docker compose down
   docker compose up -d
   ```

4. **Verificación post-actualización:**
   ```cmd
   verificar-servidor.bat
   ```

### **Versionado y Rollback**

```cmd
# Etiquetar versión actual antes de actualizar
docker tag current_image:latest current_image:backup_v1.0

# Rollback en caso de problemas
docker compose down
docker tag current_image:backup_v1.0 current_image:latest
docker compose up -d
```

### **Migración a Nuevo Servidor**

1. **En servidor antiguo:**
   ```cmd
   # Backup completo
   backup-database.bat

   # Exportar configuración
   copy .env backup_config.env
   copy docker-compose.yml backup_docker-compose.yml
   ```

2. **En servidor nuevo:**
   ```cmd
   # Instalar Docker y ACMA
   install-server-windows.bat

   # Restaurar configuración
   copy backup_config.env .env

   # Restaurar datos
   restore-database.bat
   ```

### **Compatibilidad con Versiones Futuras**

- ✅ **Docker**: Actualizaciones automáticas compatibles
- ✅ **PostgreSQL**: Migraciones automáticas entre versiones menores
- ✅ **Rails**: Actualizaciones gestionadas via Gemfile
- ✅ **Windows**: Compatible con Windows 10/11 y Server

---

## 📋 **CHECKLIST DE IMPLEMENTACIÓN**

### **Pre-Instalación**
- [ ] Verificar hardware mínimo (8GB RAM, SSD, Gigabit Ethernet)
- [ ] Windows 10 Pro/11 o Windows Server
- [ ] Conexión a internet estable
- [ ] IP estática configurada
- [ ] Puertos 3000 libres
- [ ] Permisos de administrador

### **Instalación**
- [ ] Hyper-V habilitado
- [ ] Docker Desktop instalado y funcionando
- [ ] Archivos del proyecto en `C:\ACMA\docker\`
- [ ] Configuración inicial completada (`configurar-postgres.bat`)
- [ ] Firewall configurado (puerto 3000 abierto)
- [ ] Primera ejecución exitosa (`start-server.bat`)

### **Post-Instalación**
- [ ] Acceso verificado desde navegador local
- [ ] Acceso verificado desde PC cliente
- [ ] Backup inicial creado
- [ ] Arranque automático configurado
- [ ] Backup automático programado
- [ ] Documentación entregada

### **Entrega al Cliente**
- [ ] Manual de operación entregado
- [ ] Credenciales de acceso proporcionadas
- [ ] Contacto de soporte técnico
- [ ] Capacitación básica completada
- [ ] Verificación de funcionamiento con usuario final

### **Mantenimiento Programado**
- [ ] Verificación diaria automatizada
- [ ] Backup semanal manual
- [ ] Revisión mensual de logs
- [ ] Limpieza trimestral de sistema
- [ ] Actualización semestral de software

---

## 📞 **CONTACTO Y SOPORTE**

### **En caso de problemas:**

1. **Ejecutar diagnóstico:**
   ```cmd
   verificar-servidor.bat
   ```

2. **Recopilar información:**
   - Logs de error
   - Configuración de red
   - Versión de Docker
   - Estado de servicios

3. **Contactar soporte con:**
   - Descripción detallada del problema
   - Pasos para reproducir el error
   - Screenshots o logs de error
   - Configuración del servidor

### **Recursos Adicionales**

- **Documentación Docker**: https://docs.docker.com/desktop/windows/
- **Documentación PostgreSQL**: https://www.postgresql.org/docs/
- **Soporte Microsoft**: Para temas específicos de Windows

---

## 🎯 **RESUMEN EJECUTIVO**

### **¿Qué es ACMA Server?**
Sistema de gestión empresarial basado en Ruby on Rails con base de datos PostgreSQL, ejecutándose en contenedores Docker para máxima portabilidad y facilidad de mantenimiento.

### **Beneficios Principales:**
- ✅ **Instalación simple**: Un script automatiza todo
- ✅ **Datos seguros**: PostgreSQL con backups automáticos
- ✅ **Arranque automático**: Se inicia con Windows
- ✅ **Mantenimiento mínimo**: Scripts automatizan operaciones
- ✅ **Escalable**: Fácil migración a hardware más potente

### **Tiempo de Implementación:**
- **Instalación inicial**: 30-45 minutos
- **Configuración**: 15 minutos
- **Capacitación**: 30 minutos
- **Total**: 1.5 horas aproximadamente

### **Costo de Operación:**
- **Hardware**: Una sola PC Windows
- **Software**: Todo incluido y gratuito
- **Mantenimiento**: Automatizado
- **Soporte**: Documentación completa incluida

---

**🚀 ¡Servidor ACMA listo para producción!**

*Este documento incluye todo lo necesario para implementar, operar y mantener el servidor ACMA en Windows. Para dudas específicas, consultar la sección de solución de problemas o contactar soporte técnico.*
