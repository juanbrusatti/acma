#!/bin/bash
# install-acma.sh - Instalación automatizada de ACMA en servidor nuevo
# Uso: ./install-acma.sh [IP_DEL_SERVIDOR]

set -e  # Parar en cualquier error

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Funciones de utilidad
log() {
    echo -e "${GREEN}[$(date '+%H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}"
    exit 1
}

info() {
    echo -e "${BLUE}[INFO] $1${NC}"
}

# Verificar si se ejecuta como usuario con privilegios
check_privileges() {
    if [[ $EUID -eq 0 ]]; then
        error "No ejecutar como root. Usar usuario regular con sudo."
    fi

    if ! sudo -n true 2>/dev/null; then
        error "Usuario necesita privilegios sudo. Ejecutar: sudo usermod -aG sudo $USER"
    fi
}

# Detectar sistema operativo
detect_os() {
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        OS=$ID
        VERSION=$VERSION_ID
    else
        error "No se puede detectar el sistema operativo"
    fi

    log "Sistema detectado: $OS $VERSION"
}

# Instalar Docker
install_docker() {
    log "Instalando Docker..."

    # Actualizar sistema
    sudo apt-get update
    sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release

    # Agregar clave GPG de Docker
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

    # Agregar repositorio
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    # Instalar Docker
    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

    # Agregar usuario al grupo docker
    sudo usermod -aG docker $USER

    # Iniciar Docker
    sudo systemctl enable docker
    sudo systemctl start docker

    # Verificar instalación
    if docker --version && docker compose version; then
        log "Docker instalado exitosamente"
    else
        error "Fallo en la instalación de Docker"
    fi
}

# Configurar firewall
setup_firewall() {
    log "Configurando firewall..."

    # Instalar ufw si no está
    sudo apt-get install -y ufw

    # Configurar reglas básicas
    sudo ufw --force reset
    sudo ufw default deny incoming
    sudo ufw default allow outgoing

    # Permitir SSH
    sudo ufw allow ssh

    # Permitir ACMA
    sudo ufw allow 3000/tcp comment "ACMA Server"

    # Activar firewall
    sudo ufw --force enable

    log "Firewall configurado"
}

# Crear estructura de directorios
create_directories() {
    log "Creando estructura de directorios..."

    # Directorio principal
    sudo mkdir -p /opt/acma
    sudo chown $USER:$USER /opt/acma

    # Directorios de trabajo
    mkdir -p /opt/acma/{docker,backups,logs,scripts}

    # Directorio para datos de PostgreSQL
    mkdir -p /opt/acma/docker/postgres_data
    chmod 755 /opt/acma/docker/postgres_data

    log "Estructura de directorios creada"
}

# Obtener IP del servidor
get_server_ip() {
    if [ -n "$1" ]; then
        SERVER_IP="$1"
        info "Usando IP proporcionada: $SERVER_IP"
    else
        # Intentar detectar IP automáticamente
        SERVER_IP=$(hostname -I | awk '{print $1}')
        if [ -z "$SERVER_IP" ]; then
            SERVER_IP=$(ip route get 8.8.8.8 | awk '{for(i=1;i<=NF;i++) if($i=="src") print $(i+1)}')
        fi

        if [ -z "$SERVER_IP" ]; then
            error "No se pudo detectar la IP del servidor. Proporcionar como argumento."
        fi

        info "IP detectada automáticamente: $SERVER_IP"
    fi

    # Verificar que la IP sea válida
    if ! echo "$SERVER_IP" | grep -qE '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$'; then
        error "IP inválida: $SERVER_IP"
    fi
}

# Configurar variables de entorno
setup_environment() {
    log "Configurando variables de entorno..."

    cat > /opt/acma/docker/.env << EOF
# Configuración del Servidor ACMA
# Generado automáticamente el $(date)

# Red y Conectividad
RAILS_HOST=$SERVER_IP
RAILS_PORT=3000

# Base de Datos PostgreSQL
POSTGRES_DB=acma_production
POSTGRES_USER=postgres
POSTGRES_PASSWORD=$(openssl rand -base64 32)

# Rails Environment
RAILS_ENV=production
SECRET_KEY_BASE=$(openssl rand -hex 64)

# Database URL
DATABASE_URL=postgresql://postgres:\${POSTGRES_PASSWORD}@db:5432/acma_production

# Configuración de Logs
RAILS_LOG_LEVEL=info
RAILS_SERVE_STATIC_FILES=true
EOF

    chmod 600 /opt/acma/docker/.env
    log "Variables de entorno configuradas"
}

# Crear scripts de administración
create_admin_scripts() {
    log "Creando scripts de administración..."

    # Script de inicio
    cat > /opt/acma/docker/start-server.sh << 'EOF'
#!/bin/bash
# start-server.sh - Iniciar servidor ACMA

cd "$(dirname "$0")"

echo "Iniciando servidor ACMA..."
echo "IP del servidor: $(grep RAILS_HOST .env | cut -d'=' -f2)"
echo "Puerto: $(grep RAILS_PORT .env | cut -d'=' -f2)"

# Verificar que Docker esté corriendo
if ! docker info >/dev/null 2>&1; then
    echo "ERROR: Docker no está corriendo"
    exit 1
fi

# Iniciar servicios
docker compose up -d

# Esperar a que los servicios estén listos
echo "Esperando a que los servicios estén listos..."
sleep 10

# Verificar estado
docker compose ps

# Verificar conectividad
SERVER_IP=$(grep RAILS_HOST .env | cut -d'=' -f2)
if curl -f -s http://$SERVER_IP:3000 >/dev/null; then
    echo "✓ Servidor ACMA iniciado exitosamente"
    echo "  Acceso: http://$SERVER_IP:3000"
else
    echo "⚠ Servidor iniciado pero no responde. Verificar logs:"
    echo "  docker compose logs"
fi
EOF

    # Script de parada
    cat > /opt/acma/docker/stop-server.sh << 'EOF'
#!/bin/bash
# stop-server.sh - Parar servidor ACMA

cd "$(dirname "$0")"

echo "Parando servidor ACMA..."
docker compose down

echo "✓ Servidor ACMA detenido"
EOF

    # Script de estado
    cat > /opt/acma/docker/status.sh << 'EOF'
#!/bin/bash
# status.sh - Verificar estado del servidor ACMA

cd "$(dirname "$0")"

echo "=== Estado del Servidor ACMA ==="
echo "Fecha: $(date)"
echo

# Estado de servicios
echo "Servicios Docker:"
docker compose ps

# Recursos
echo
echo "Uso de recursos:"
docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}"

# Conectividad
echo
SERVER_IP=$(grep RAILS_HOST .env | cut -d'=' -f2)
echo "Verificando conectividad..."
if curl -f -s http://$SERVER_IP:3000 >/dev/null; then
    echo "✓ Servidor responde en http://$SERVER_IP:3000"
else
    echo "✗ Servidor no responde"
fi

# Base de datos
echo
echo "Estado de base de datos:"
if docker compose exec -T db pg_isready -U postgres >/dev/null 2>&1; then
    echo "✓ PostgreSQL funcionando"
    SIZE=$(docker compose exec -T db psql -U postgres -d acma_production -c "SELECT pg_size_pretty(pg_database_size('acma_production'));" -t | tr -d ' ')
    echo "  Tamaño de DB: $SIZE"
else
    echo "✗ PostgreSQL no responde"
fi
EOF

    # Hacer scripts ejecutables
    chmod +x /opt/acma/docker/*.sh

    log "Scripts de administración creados"
}

# Configurar servicio systemd
setup_systemd_service() {
    log "Configurando servicio systemd..."

    sudo tee /etc/systemd/system/acma.service > /dev/null << EOF
[Unit]
Description=ACMA Server
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/opt/acma/docker
ExecStart=/opt/acma/docker/start-server.sh
ExecStop=/opt/acma/docker/stop-server.sh
User=$USER
Group=$USER

[Install]
WantedBy=multi-user.target
EOF

    # Habilitar servicio
    sudo systemctl daemon-reload
    sudo systemctl enable acma.service

    log "Servicio systemd configurado"
}

# Configurar cron para backups automáticos
setup_cron_backups() {
    log "Configurando backups automáticos..."

    # Crear script de backup automático
    cat > /opt/acma/scripts/auto-backup.sh << 'EOF'
#!/bin/bash
# auto-backup.sh - Backup automático diario

cd /opt/acma/docker

# Backup comprimido diario
echo "4" | ./backup-database.sh

# Limpiar backups antiguos (más de 30 días)
find backups/ -name "backup_acma_*" -mtime +30 -delete

# Log del backup
echo "$(date): Backup automático completado" >> /opt/acma/logs/backup.log
EOF

    chmod +x /opt/acma/scripts/auto-backup.sh

    # Agregar a crontab
    (crontab -l 2>/dev/null; echo "0 2 * * * /opt/acma/scripts/auto-backup.sh") | crontab -

    log "Backups automáticos configurados (diarios a las 2:00 AM)"
}

# Crear documentación local
create_local_docs() {
    log "Creando documentación local..."

    cat > /opt/acma/README-SERVIDOR.md << EOF
# ACMA Server - Instalado el $(date)

## Información del Servidor
- **IP del Servidor**: $SERVER_IP
- **Puerto**: 3000
- **Acceso**: http://$SERVER_IP:3000
- **Usuario del Sistema**: $USER
- **Directorio de Instalación**: /opt/acma

## Comandos Principales

### Gestión del Servidor
\`\`\`bash
# Iniciar servidor
cd /opt/acma/docker && ./start-server.sh

# Parar servidor
cd /opt/acma/docker && ./stop-server.sh

# Ver estado
cd /opt/acma/docker && ./status.sh

# Ver logs
cd /opt/acma/docker && docker compose logs

# Reiniciar servicios
cd /opt/acma/docker && docker compose restart
\`\`\`

### Gestión con Systemd
\`\`\`bash
# Iniciar con systemctl
sudo systemctl start acma

# Parar con systemctl
sudo systemctl stop acma

# Ver estado
sudo systemctl status acma

# Habilitar inicio automático
sudo systemctl enable acma
\`\`\`

### Backups
\`\`\`bash
# Backup manual
cd /opt/acma/docker && ./backup-database.sh

# Ver backups
ls -la /opt/acma/docker/backups/

# Restaurar backup
cd /opt/acma/docker && ./restore-database.sh
\`\`\`

## Archivos Importantes
- **Configuración**: /opt/acma/docker/.env
- **Logs**: /opt/acma/logs/
- **Backups**: /opt/acma/docker/backups/
- **Datos de DB**: /opt/acma/docker/postgres_data/

## Solución de Problemas
Para problemas consultar:
- README-SERVIDOR-COMPLETO.md
- README-TROUBLESHOOTING.md

## Comandos de Emergencia
\`\`\`bash
# Reinicio completo
cd /opt/acma/docker
docker compose down
docker compose up -d --build

# Backup de emergencia
cd /opt/acma/docker
echo "2" | ./backup-database.sh
\`\`\`

## Contacto
- **Instalado por**: $(whoami)
- **Fecha de Instalación**: $(date)
- **Versión del Sistema**: $(lsb_release -d | cut -f2)
EOF

    log "Documentación local creada"
}

# Función principal de instalación
main() {
    echo "======================================"
    echo "    INSTALADOR AUTOMÁTICO ACMA"
    echo "======================================"
    echo

    # Verificaciones previas
    check_privileges
    detect_os
    get_server_ip "$1"

    # Confirmación
    echo "Configuración de instalación:"
    echo "- Sistema: $OS $VERSION"
    echo "- Usuario: $USER"
    echo "- IP del servidor: $SERVER_IP"
    echo "- Directorio: /opt/acma"
    echo
    read -p "¿Continuar con la instalación? (s/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[SsYy]$ ]]; then
        error "Instalación cancelada por el usuario"
    fi

    # Proceso de instalación
    log "Iniciando instalación de ACMA..."

    # 1. Instalar Docker
    if ! command -v docker &> /dev/null; then
        install_docker
        warn "Docker instalado. Es necesario reiniciar la sesión o ejecutar 'newgrp docker'"
    else
        log "Docker ya está instalado"
    fi

    # 2. Crear directorios
    create_directories

    # 3. Configurar firewall
    setup_firewall

    # 4. Configurar variables de entorno
    setup_environment

    # 5. Crear scripts de administración
    create_admin_scripts

    # 6. Configurar servicio systemd
    setup_systemd_service

    # 7. Configurar backups automáticos
    setup_cron_backups

    # 8. Crear documentación
    create_local_docs

    # Finalización
    echo
    log "¡Instalación completada exitosamente!"
    echo
    echo "Próximos pasos:"
    echo "1. Copiar los archivos de la aplicación ACMA a /opt/acma/docker/"
    echo "2. Asegurar que docker-compose.yml y Aberturas/ estén en /opt/acma/docker/"
    echo "3. Ejecutar: cd /opt/acma/docker && ./start-server.sh"
    echo
    echo "Acceso al servidor: http://$SERVER_IP:3000"
    echo "Documentación: /opt/acma/README-SERVIDOR.md"
    echo
    warn "IMPORTANTE: Guardar la contraseña de PostgreSQL de /opt/acma/docker/.env"
}

# Ejecutar función principal
main "$@"
