# ✅ Lista de Verificación - Testing del Instalador

## 🧪 Pruebas obligatorias ANTES de entregar

### Prueba 1: PC Windows limpia (SIN Docker)
- [ ] Ejecutar instalador como administrador
- [ ] Verificar que abre navegador para Docker
- [ ] Instalar Docker Desktop manualmente
- [ ] Reiniciar PC si Docker lo pide
- [ ] Ejecutar ACMA desde acceso directo
- [ ] Verificar que carga la aplicación Rails
- [ ] Probar funciones básicas de la app
- [ ] Cerrar ACMA y verificar que Docker se detiene

### Prueba 2: PC Windows CON Docker ya instalado
- [ ] Ejecutar instalador
- [ ] Verificar instalación rápida (sin descargar Docker)
- [ ] Ejecutar ACMA
- [ ] Verificar funcionamiento normal

### Prueba 3: Múltiples ejecuciones
- [ ] Cerrar ACMA completamente
- [ ] Volver a abrir desde acceso directo
- [ ] Verificar que inicia más rápido (Docker ya corriendo)
- [ ] Repetir 3-4 veces

### Prueba 4: Desinstalación
- [ ] Panel de Control → Desinstalar ACMA
- [ ] Verificar que se elimina correctamente
- [ ] Verificar que NO elimina Docker (correcto)
- [ ] Reinstalar y probar nuevamente

## 🚨 Problemas comunes y soluciones

### Error: "No se puede conectar"
**Causa:** Docker no está corriendo
**Solución:** Abrir Docker Desktop, esperar que inicie

### Error: "Puerto ocupado"
**Causa:** Otro proceso usa puerto 3000
**Solución:** `netstat -ano | findstr :3000` y matar proceso

### Error: "Permisos denegados"
**Causa:** No se ejecutó como administrador
**Solución:** Clic derecho → Ejecutar como administrador

## ✅ Criterios de aprobación
- [ ] Instala correctamente en PC limpia
- [ ] Funciona en PC con Docker existente
- [ ] Aplicación Rails carga completamente
- [ ] No hay errores en consola
- [ ] Desinstala limpiamente
- [ ] Iconos se muestran correctamente
- [ ] Accesos directos funcionan
