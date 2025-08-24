# 📋 INSTRUCCIONES PARA INSTALAR EN CLIENTE

## 🎯 **PROCESO COMPLETO: GitHub + Docker**

### **Paso 1: Instalar Git en Windows**
1. Descargar Git desde: https://git-scm.com/download/win
2. Instalar con opciones por defecto
3. Reiniciar la PC

### **Paso 2: Instalar Docker Desktop**
1. Descargar Docker Desktop desde: https://www.docker.com/products/docker-desktop
2. Instalar y reiniciar la PC
3. Abrir Docker Desktop y esperar que arranque

### **Paso 3: Clonar el Repositorio**
```bash
# Abrir CMD o PowerShell como Administrador
cd C:\
git clone https://github.com/juanbrusatti/acma.git
cd C:\acma
git checkout deploy
git pull origin deploy
```

### Paso 3.5:
- Cambiar la ip del main.js para la build
- Cambiar en el .env la ip del servidor

### **Paso 4: Copiar el archivo de configuración**
```bash
# IMPORTANTE: Copiar el archivo .env que se proporcionó
# en la carpeta C:\acma\docker\
# (Asegurarse de que se llame exactamente ".env")
```

### **Paso 5: Ejecutar la Aplicación**
```bash
# Ir a la carpeta del Docker
cd C:\acma\docker

# Ejecutar el script
1-start_server.bat
```

### **¡LISTO!**
- La aplicación estará corriendo en: **http://localhost:3000**
- Lo siguiente es desde el Admin de Tareas hacer que el script se ejecute al iniciar la pc.
- Tambien hacer backups automaticos (preguntar cada cuanto)

---

## 📄 **ARCHIVO .env REQUERIDO**

**IMPORTANTE**: Antes de ejecutar, debe copiar el archivo `.env` que se le proporcionó en:
```
C:\acma\docker\.env
```

Este archivo contiene:
- Configuración de la base de datos
- Claves de seguridad
- Configuración del servidor

**Sin este archivo, la aplicación NO funcionará.**

---

## 🔧 **COMANDOS ÚTILES**

### **Para iniciar el servidor:**
```bash
cd C:\acma\docker
1-start_server.bat
```

### **Para hacer backup:**
```bash
cd C:\acma\docker
2-backup_db.bat
```

### **Para restaurar backup:**
```bash
cd C:\acma\docker
3-restore.bat
```

### **Para actualizar el código:**
```bash
cd C:\acma
git pull origin deploy
cd docker
docker compose up --build -d
```

---

## ⚠️ **IMPORTANTE**

- **NO necesita instalar Ruby, Rails, PostgreSQL**
- **Todo está en Docker**
- **Solo necesita Git + Docker Desktop**
- **CRÍTICO: Debe copiar el archivo .env en C:\acma\docker\ antes de ejecutar**
- **Los datos se guardan en C:\acma\docker\postgres_data\**

---

## 🆘 **En caso de problemas**

### **"Esperando a que Docker arranque" se queda mucho tiempo**
1. **Abrir Docker Desktop manualmente** y esperar que aparezca el ícono verde
2. **Verificar que Docker esté funcionando:**
   ```bash
   docker --version
   docker info
   ```
3. **Si Docker no responde:** Reiniciar Docker Desktop o la PC

### **Otros problemas comunes**
1. **Ejecutar diagnóstico automático:**
   ```bash
   cd C:\acma\docker
   0-diagnostico.bat
   ```

2. **Verificar que Docker esté corriendo:**
   ```bash
   docker --version
   ```

3. **Ver logs de la aplicación:**
   ```bash
   cd C:\acma\docker
   docker compose logs web
   ```

4. **Reiniciar todo:**
   ```bash
   cd C:\acma\docker
   docker compose down
   docker compose up -d
   ```
