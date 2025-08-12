# 🔧 ACMA - Manual de Actualizaciones

## **📦 1. Primera release**

### 1.1 Preparar PC servidor
Requisitos:
- **Sistema operativo**: Windows 10/11, Ubuntu o cualquier Linux moderno.
- **Docker** y **Docker Compose** instalados.
- **Git**.
- Al menos **4 GB de RAM** y **10 GB libres** en disco.
- Conexión a la misma red que las PCs clientes.

### 1.2 Pasos de instalación inicial
1. Copiar el proyecto Rails (con `docker-compose.yml`) a la PC servidor.
2. Crear carpeta para persistencia de la base de datos, por ejemplo:
   `./Aberturas/storage/development.sqlite3`
3. Construir la imagen por primera vez:
```bash
docker compose build web
```
4. Crear la base de datos y ejecutar migraciones:
```bash
docker compose run --rm web bundle exec rails db:setup RAILS_ENV=production
```
5. Levantar el servidor
```bash
docker compose up -d
```
6. Anotar la IP local del servidor (ej. 192.168.0.10)
7. Configurar el .exe de Electron para apuntar a la IP del servidor

## **🔄 2. Futuras releases**

### 2.1 Antes del deploy
- Hacer backup de la DB:
```bash
cd acma
mkdir -p backups
cp ./Aberturas/storage/development.sqlite3 backups/dev_$(date +"%Y%m%d_%H%M%S").sqlite3
```
- Revisar que las migraciones nuevas no borren datos.
- Probar migraciones localmente con copia de la DB de producción.

### 2.2 Durante el deploy
1. Apagar app:
```bash
docker compose down
```
2. Actualizar el código por el nuevo
```bash
git pull
```
3. Reconstruir imagen
```bash
docker compose build web
```
4. Correr migraciones
```bash
docker compose run --rm web bundle exec rails db:migrate RAILS_ENV=production
```
5. Levantar app:
```bash
docker compose up -d
```

### 2.2 Despues del deploy
- Probar funcionalidades clave.
- Confirmar que los datos antiguos siguen intactos.
- Revisar logs
```bash
docker compose logs -f web
```

## **⚠️ 3. Reglas de oro para cambios de esquema**
- Agregar columnas → primero nullable o con valor por defecto.
- Renombrar columnas → crear nueva, copiar datos, borrar vieja en otra release.
- Eliminar columnas/tablas → en releases posteriores.
- Validaciones nuevas → asegurarse que los datos existentes las cumplan.


### **🛠 4. Para restaurar un Backup**
```bash
docker compose down
cp backups/dev_YYYYMMDD_HHMMSS.sqlite3 ./Aberturas/storage/development.sqlite3
docker compose up -d
```

### **🐍 5. Integracion futura con Python**
1.  Incluir Python en el mismo contenedor Rails
   - Instalar Python y librerías necesarias en el Dockerfile.
   - Ejecutar scripts Python desde Rails con:
      ```bash
      system("python3 script.py arg1 arg2")
      ```
