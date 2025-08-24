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

### **Paso 4: Ejecutar la Aplicación**
```bash
# Ir a la carpeta del Docker
cd C:\acma\docker

# Ejecutar el script
1-start_server.bat
```

### **¡LISTO!** 
- La aplicación estará corriendo en: **http://localhost:3000**

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
- **Los datos se guardan en C:\acma\docker\postgres_data\**

---

## 🆘 **En caso de problemas**

1. **Verificar que Docker esté corriendo:**
   ```bash
   docker --version
   ```

2. **Ver logs de la aplicación:**
   ```bash
   cd C:\acma\docker
   docker compose logs web
   ```

3. **Reiniciar todo:**
   ```bash
   cd C:\acma\docker
   docker compose down
   docker compose up -d
   ```
