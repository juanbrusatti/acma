# 🔧 ACMA - Manual de Actualizaciones

## 📝 Cómo crear una nueva versión

### 1. Modificar la aplicación Rails
- Editar archivos en `/docker/Aberturas/`
- Para cuando hayan cambios en la base de datos `sudo docker compose exec web rm /app/tmp/db_setup_done`
- Probar cambios localmente con `docker compose up`

### 2. Actualizar versión
- Editar `electron-app/package.json`
- Cambiar la línea: `"version": "1.0.0"` → `"version": "1.1.0"`

### 3. Reconstruir instalador
```bash
cd electron-app
npm run build-win
```

### 4. El nuevo instalador estará en:
```
dist/ACMA - Sistema de Aberturas Setup 1.1.0.exe
```

## 🔄 Proceso de actualización para usuarios

### Opción A: Instalador sobre instalador
- Los usuarios ejecutan el nuevo .exe
- Se instala sobre la versión anterior
- Mantiene configuraciones

### Opción B: Desinstalar y reinstalar
- Panel de Control → Desinstalar ACMA
- Ejecutar nuevo instalador
- Configuraciones se pierden

## 📊 Versionado recomendado

- **1.0.x** - Correcciones de bugs
- **1.x.0** - Nuevas características menores
- **x.0.0** - Cambios importantes

## 🐛 Debug y logs

### Si hay problemas:
1. Verificar Docker Desktop está corriendo
2. Revisar logs de contenedor:
   ```bash
   docker compose logs
   ```
3. Verificar puertos:
   ```bash
   netstat -ano | findstr :3000
   ```

