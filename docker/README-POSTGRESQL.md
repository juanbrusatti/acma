# Migración a PostgreSQL con Docker

Este proyecto ha sido configurado para usar PostgreSQL en lugar de SQLite, con persistencia de datos a través de volúmenes de Docker.

## 🗄️ Configuración de la Base de Datos

### Volumen Persistente
- **Carpeta local**: `./postgres_data/` (en el directorio docker)
- **Carpeta en contenedor**: `/var/lib/postgresql/data`
- **Beneficio**: Si el contenedor se elimina, los datos permanecen en tu PC

### Credenciales por Defecto
- **Usuario**: `postgres`
- **Contraseña**: `Acma2024!Secure`
- **Base de datos de producción**: `acma_production`
- **Puerto**: `5432`

## 🚀 Cómo usar

### 1. Configurar antes del primer uso
```bash
# Windows
configurar-postgres.bat

# Linux/Mac
nano .env  # Editar manualmente
```

### 2. Primer inicio (instalación nueva)
```bash
# Windows
start-server.bat

# Linux/Mac
./start-server.sh
```

### 3. Si tienes datos en SQLite y quieres migrarlos
```bash
# 1. Primero, levantar PostgreSQL
docker-compose up -d db

# 2. Esperar que PostgreSQL esté listo y ejecutar migración
./migrate_sqlite_to_postgres.sh

# 3. Levantar la aplicación
docker-compose up web
```

### 4. Inicios posteriores
```bash
# Windows
start-server.bat

# Linux/Mac
./start-server.sh
```

## 📁 Estructura de Archivos

```
docker/
├── postgres_data/          # ⭐ DATOS PERSISTENTES DE POSTGRESQL
├── docker-compose.yml      # Configuración de contenedores
├── entrypoint.sh          # Script de inicialización
├── migrate_sqlite_to_postgres.sh  # Script de migración (opcional)
└── Aberturas/
    ├── Gemfile            # Actualizado con gem 'pg'
    ├── config/database.yml # Configuración PostgreSQL
    └── ...
```

## 🔧 Comandos Útiles

### Acceder a PostgreSQL directamente
```bash
# Desde tu sistema local
psql -h localhost -p 5432 -U postgres -d acma_development

# Desde dentro del contenedor
docker-compose exec db psql -U postgres -d acma_development
```

### Backup de la base de datos
```bash
# Crear backup
docker-compose exec db pg_dump -U postgres acma_development > backup.sql

# Restaurar backup
docker-compose exec -T db psql -U postgres acma_development < backup.sql
```

### Gestión de Rails
```bash
# Ejecutar migraciones
docker-compose exec web bundle exec rails db:migrate

# Crear seed data
docker-compose exec web bundle exec rails db:seed

# Acceder a Rails console
docker-compose exec web bundle exec rails console
```

## 🛡️ Seguridad en Producción

Para producción, **CAMBIA** estas configuraciones:

1. **Contraseñas**: Usa contraseñas seguras en lugar de "password"
2. **Variables de entorno**: Usa archivos `.env` o secrets de Docker
3. **Red**: No expongas el puerto 5432 si no es necesario

Ejemplo para producción:
```yaml
environment:
  POSTGRES_PASSWORD_FILE: /run/secrets/postgres_password
secrets:
  postgres_password:
    file: ./secrets/postgres_password.txt
```

## 📋 Notas Importantes

1. **Datos persistentes**: Los datos se guardan en `./postgres_data/` y NO se pierden al reiniciar Docker
2. **Primera vez**: El setup puede tardar unos minutos la primera vez
3. **Migración**: Solo usa el script de migración si ya tienes datos en SQLite
4. **Backup**: Siempre haz backup antes de cambios importantes

## 🐛 Solución de Problemas

### "Database does not exist"
```bash
docker-compose exec web bundle exec rails db:create
docker-compose exec web bundle exec rails db:migrate
```

### "Connection refused"
```bash
# Verificar que PostgreSQL está corriendo
docker-compose ps
# Debería mostrar el servicio 'db' como 'Up'
```

### Resetear completamente
```bash
# ⚠️ ESTO BORRA TODOS LOS DATOS
docker-compose down -v
rm -rf postgres_data/
docker-compose up --build
```
