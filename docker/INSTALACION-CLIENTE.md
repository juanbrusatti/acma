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

# Opción 1: Servidor en segundo plano (recomendado)
1-start_server.bat

# Opción 2: Servidor con logs visibles (para diagnóstico)
1-start_server_con_logs.bat
```

### **Para verificar conectividad de red:**
```bash
cd C:\acma\docker
verificar-red.bat
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

### **No me puedo conectar desde otra PC en la red**
1. **Verificar la IP del servidor:**
   ```bash
   ipconfig
   ```
2. **Ejecutar verificador de red:**
   ```bash
   cd C:\acma\docker
   verificar-red.bat
   ```
3. **Configurar firewall de Windows:**
   - Ir a "Panel de Control" > "Sistema y seguridad" > "Firewall de Windows Defender"
   - Clic en "Permitir una aplicación o característica"
   - Buscar "Docker Desktop" y asegurarse que esté permitido
   - O agregar excepción para puerto 3000

4. **Desde la PC cliente, probar:**
   ```bash
   ping [IP-DEL-SERVIDOR]
   ```

### **El script se cierra después de ejecutar**
- **Usar:** `1-start_server_con_logs.bat` en lugar de `1-start_server.bat`
- **No cerrar la ventana** hasta que quieras parar el servidor
- **Para parar:** Presionar Ctrl+C en la ventana

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
