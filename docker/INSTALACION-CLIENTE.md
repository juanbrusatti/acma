# 📋 INSTRUCCIONES PARA INSTALAR EN CLIENTE

## 🎯 **PROCESO COMPLETO: GitHub + Docker**

### **Paso 1: Copiar carpeta "docker"**
1. Entrar al repo en google, descargar la carpeta "docker" y descomprimirla en C:\acma\docker
2. Copiar el .env(docker) y master.key (docker/Aberturas/config) 

### **Paso 2: Instalar Docker Desktop**
1. Descargar Docker Desktop desde: https://www.docker.com/products/docker-desktop
2. Instalar y reiniciar la PC
3. Abrir Docker Desktop y esperar que arranque
4. Si estoy en Windows 10 Pro tengo que instalar Hyper-v:
   ```bash
   dism.exe /Online /Enable-Feature:Microsoft-Hyper-V /All /NoRestart
   ```
5. Reiniciar la PC
6. Chequear que en Docker Desktop no aparezca ningun error.
7. Marcar la casilla "Start Docker Desktop when you sign in to your computer"
8. Desmarcar la casilla "Open Docker Dashboard when Docker Desktop starts"
9. Cambiar en Settings → General → Desmarcar la opción “Use the WSL 2 based engine” → Aceptá y reiniciá Docker Desktop.
10. Si hay otro error preguntarle a Gepeto

- Si no puedo activar Hyper-V le instalo wsl:
   ```bash
   wsl --install
   wsl --update
   ```

### Paso 3:
1. Abrí las conexiones de red
   Win + R → escribí ncpa.cpl → Enter.

2. Elegí el adaptador (Wi-Fi o Ethernet, según uses).
   Botón derecho → Propiedades.

3. Seleccioná Protocolo de Internet versión 4 (TCP/IPv4)
   Clic en Propiedades.

4. Marcá Usar la siguiente dirección IP e ingresá:
   Dirección IP: elegí una fija dentro de tu red. Ejemplo: 192.168.1.150
   Máscara de subred: 255.255.255.0
   Puerta de enlace predeterminada: la IP de tu router (mirala con ipconfig, suele ser 192.168.1.1).
   
   (Si la puerta es *.*.0.*, la Ip fija en el tercer componente tambien debe tener un 0, lo mismo con el 1)

5. En Servidor DNS podés poner:
   8.8.8.8 y 8.8.4.4 (Google)

6. Cambiar la ip del main.js para la build, por el que acabamos de configurar.
7. Cambiar en el .env la ip del servidor.

### **Paso 4: Instalar Postgres**
1. Descargar Postgres 17 desde: https://www.postgresql.org/
2. Instalarlo (dejando todas las casillas marcadas).
3. NO INSTALAR EL STACK BUILDER.
3. Me va a pedir una contraseña, ingreso la que esta en .env
4. Comprobar si se descargo correctamente en /"Program Files"/PostgreSQL/17/bin usando psql -U postgres
5. Si todo esta instalado correctamente me va a pedir un password, debo ingresar la misma que antes.
6. Luego, debo correr los siguientes comandos:
- ``` CREATE DATABASE acma_production; ```
- ``` CREATE USER acma WITH ENCRYPTED PASSWORD <usada en .env>; ```
- ``` GRANT ALL PRIVILEGES ON DATABASE acma_production TO acma; ```
7. Si tengo algun problema para correr el programa me fijo lo siguiente:
  - Ir a /"Program Files"/PostgreSQL/17/data/postgresql.conf y buscar esta linea: listen_addresses = '*'. Si no esta el '*' debemos ponerlo.
  - Habilitar el puerto para Postgres: ir a 'Windows Defender Firewall con Seguridad Avanzada" --> Reglas de entrada --> Nueva Regla --> Puerto --> Marcamos TCP y ponemos el puerto (5432).
  - El puerto 5432 podria estar ocupado, para resolver esto tenemos dos opciones: la primera es usar otro puerto y actualizarlo en todos los archivos; por otro lado podriamos ver si el proceso que esta en ese puerto se puede matar, para ello vamos a hacer ejecutar en la terminal ``` netstat -ano | findstr "5432" ```, y el PID resultante lo matamos de la siguiente manera: ``` taskkill /PID <...> /F ```
  - Verificamos que el Posgres este corriendo, si no lo ponemos en ejecución, para ello hacemos lo siguiente: Win + R → escribí services.msc → Enter. Luego, buscamos Postgres  y deberia estar en ejecución, si no esta lo activamos. Como ultima opción, podemos desactivarlo y activarlo de nuevo por las dudas.

### **Paso 5: Ejecutar la Aplicación**
```bash
# Ir a la carpeta del Docker
cd C:\acma\docker

# Ejecutar el script
1-start_server.bat
```

### **Paso 6: Crear las Tareas**
1. Tarea para que se ejecute apenas se prenda la pc el script de inicio
   1. Win + R (taskschd.msc)
   2. En el panel de acciones, selecciona Crear Tarea.
   3. Dale un nombre a la tarea (ej. Iniciar_Docker_Rails).
   4. Para el activador, elige Cuando se inicie el equipo.
   5. En la acción, selecciona Iniciar un programa, y poner el script.
   6. Hacerlo con permisos de sudo y Oculta
2. Tarea para backups automaticos (lunes y jueves a las 11:00 AM), mismo procedimiento pero poniendo fecha y corriendo backup_db.bat. Luego, para que no nos pida contraseña,
   cada vez que hacemos el backup tenemos que hacer lo siguiente:
      - Escribimos %APPDATA% en el buscador de windows
      - Dentro de la carpeta Roaming, creamos una carpeta llamada "postgresql"
      - Dentro de la carpeta postgresql, creamos un archivo llamado "pgpass.conf"
      - Dentro del archivo pgpass.conf, escribimos la siguiente línea: ``` localhost:5432:acma_production:postgres:tu_contraseña ```
      - Guardamos el archivo y lo cerramos
      - Luego, abrimos la terminal de windows como administrador y escribimos el siguiente comando: 
            ``` icacls "C:\Users\TuUsuario\AppData\Roaming\postgresql\pgpass.conf" /inheritance:r /grant:r "username:R" ```
            Si no sabemos cual es nuestro username hacemos lo siguiente para obtenerlo: ```echo username ```

### **Paso 7: Comprobar que todo anda correctamente**
1. Verificar que el contenedor esté corriendo:
```bash
docker ps
```
2. Probar acceso a la aplicación:
```bash
curl http://localhost:3000
```
3. Probar hacer un backup
4. Probar restaurar el backup

### **Paso 7: Crear la build de Electron**
1. Poner la IP correcta en el main.js
2. Ejecutar el siguiente comando en la carpeta electron-app(en mi pc):
```bash
npm run build
```
3. Compartir la build a Ariana

### **¡LISTO!**
- La aplicación estará corriendo.


## 🔧 **COMANDOS ÚTILES**

### **Para iniciar el servidor:**
```bash
cd C:\acma\docker

# Opción 1: Servidor en segundo plano (recomendado)
1-start_server.bat

# Opción 2: Servidor con logs visibles (para diagnóstico)
1-start_server.bat
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
