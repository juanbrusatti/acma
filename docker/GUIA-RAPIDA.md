# ⚡ GUÍA RÁPIDA: Instalación en 5 Pasos

## 🎯 **PARA EL CLIENTE (Primera vez)**

### Paso 1: Preparar la PC
```bash
# Descargar Docker Desktop desde:
https://www.docker.com/products/docker-desktop

# Instalar y reiniciar la PC
```

### Paso 2: Copiar archivos del proyecto
```bash
# Crear carpeta en la PC del cliente:
C:\ACMA\
# Copiar toda la carpeta 'docker' ahí
```

### Paso 3: Configurar IP del servidor
```batch
# Ejecutar (Windows):
cd C:\ACMA\docker
configurar-postgres.bat

# Cambiar la IP por la IP real de la PC servidor
# Ejemplo: 192.168.1.100
```

### Paso 4: Iniciar por primera vez
```batch
# Ejecutar:
start-server.bat
```

### Paso 5: Verificar
```
# Abrir navegador y ir a:
http://IP_DEL_SERVIDOR:3000

# Si se ve la app, ¡funciona! ✅
```

---

## 🔄 **PARA USO DIARIO**

### Encender servidor (cada día):
```batch
cd C:\ACMA\docker
start-server.bat
```

### Apagar servidor (al final del día):
```batch
cd C:\ACMA\docker
docker compose down
```

---

## 🆘 **SI ALGO SALE MAL**

### "No se puede conectar"
1. Verificar que Docker Desktop esté corriendo
2. Ejecutar: `configurar-postgres.bat`
3. Verificar la IP del servidor
4. Reiniciar: `docker compose down` y luego `start-server.bat`

### "Error de base de datos"
```batch
# Reiniciar completamente:
docker compose down -v
start-server.bat
```

### "Va muy lento"
1. Abrir Docker Desktop → Settings → Resources
2. Aumentar RAM a 6GB mínimo
3. Aumentar CPU a 4 cores mínimo

---

## 📞 **NÚMEROS IMPORTANTES**

- **Puerto del servidor**: 3000
- **Puerto PostgreSQL**: 5432 (solo interno)
- **Carpeta de datos**: `C:\ACMA\docker\postgres_data\`
- **Archivo de configuración**: `C:\ACMA\docker\.env`

**⚠️ NUNCA BORRAR**: La carpeta `postgres_data` contiene TODA la base de datos.
