# ACMA - Instalador Todo en Uno

Este es un instalador completo para la aplicación ACMA que incluye detección e instalación automática de Docker Desktop.

## 🎯 Objetivo

Crear un archivo `.exe` que:
1. **Primera ejecución**: Detecta si Docker está instalado, lo instala si es necesario, y lanza la aplicación
2. **Siguientes ejecuciones**: Verifica que Docker esté corriendo y lanza la aplicación directamente

## ✨ Características

- 🔍 **Detección automática de Docker Desktop**
- 📥 **Descarga e instalación automática de Docker** (si no está instalado)
- 🚀 **Inicio automático de contenedores**
- 💻 **Interfaz gráfica amigable** con ventanas de progreso
- 🛡️ **Manejo robusto de errores**
- 📦 **Instalador profesional con NSIS**
- 🔒 **Prevención de múltiples instancias**

## 🛠️ Requisitos

### Para desarrollar:
- Node.js 18+
- npm
- Windows 10/11 (para generar el instalador .exe)

### Para el usuario final:
- Windows 10/11
- Permisos de administrador (para instalar Docker)
- Conexión a internet (para descargar Docker si es necesario)

## 📁 Estructura del proyecto

```
electron-app/
├── main.js                    # Aplicación principal de Electron
├── docker-installer.js       # Utilidades para manejar Docker
├── package.json              # Configuración y dependencias
├── installer.nsh             # Script personalizado NSIS
├── build.sh                  # Script de construcción (Linux/Mac)
├── build.ps1                 # Script de construcción (Windows)
├── icon.png                  # Icono de la aplicación (256x256)
├── icon.ico                  # Icono para Windows (múltiples tamaños)
└── ICONOS-README.md          # Instrucciones para crear iconos
```

## 🚀 Cómo construir el instalador

### Opción 1: Script automatizado (Windows)
```powershell
# Desde PowerShell como administrador
cd electron-app
.\build.ps1
```

### Opción 2: Script automatizado (Linux/Mac)
```bash
cd electron-app
chmod +x build.sh
./build.sh
```

### Opción 3: Manual
```bash
cd electron-app
npm install
npm run build-win
```

## 📦 Archivos generados

Después de la construcción, encontrarás en `dist/`:

- `ACMA - Sistema de Aberturas Setup X.X.X.exe` - **Instalador principal**
- `win-unpacked/` - Aplicación desempaquetada (para desarrollo)

## 🔧 Configuración avanzada

### Personalizar el instalador

Edita `package.json` en la sección `build.nsis`:

```json
"nsis": {
  "oneClick": false,                    // Instalador tradicional
  "perMachine": true,                   // Instalar para todos los usuarios
  "allowElevation": true,               // Permitir elevación de permisos
  "createDesktopShortcut": true,        // Crear acceso directo
  "shortcutName": "Tu App Name"         // Nombre del acceso directo
}
```

### Personalizar detección de Docker

Edita `docker-installer.js` para cambiar:

- URL de descarga de Docker
- Tiempo de espera para inicio
- Mensajes de error personalizados

## 🐳 Funcionamiento con Docker

### Primera instalación:
1. ✅ Verifica si Docker está instalado
2. 📥 Si no está: descarga Docker Desktop automáticamente
3. 🔧 Guía al usuario través de la instalación
4. 🔄 Puede requerir reinicio del sistema
5. 🚀 Inicia Docker Desktop automáticamente
6. 📦 Levanta el contenedor de la aplicación Rails
7. 🌐 Abre la aplicación en Electron

### Siguientes ejecuciones:
1. ✅ Verifica que Docker esté corriendo
2. 🚀 Si no está corriendo: lo inicia automáticamente
3. 📦 Levanta el contenedor (si no está ya corriendo)
4. 🌐 Abre la aplicación inmediatamente

## 🎨 Personalización visual

### Ventanas de progreso
Las ventanas de progreso tienen un diseño moderno con:
- Gradientes de color
- Efectos de blur
- Animaciones suaves
- Indicadores de progreso

Para personalizar, edita la función `showProgressWindow` en `main.js`.

### Iconos
Coloca tus iconos personalizados:
- `icon.png` - 256x256 píxeles, formato PNG
- `icon.ico` - Múltiples tamaños, formato ICO

Consulta `ICONOS-README.md` para instrucciones detalladas.

## 🔍 Debugging

### Logs de la aplicación
Los logs se muestran en la consola de desarrollo:
```javascript
// En main.js
console.log("Estado de Docker:", dockerStatus);
```

### Verificar contenedor manualmente
```bash
docker ps                              # Ver contenedores corriendo
docker compose -f docker-compose.yml logs  # Ver logs del contenedor
```

### Probar sin compilar
```bash
npm start  # Ejecutar en modo desarrollo
```

## 🚨 Solución de problemas

### Error: "Docker no se pudo iniciar"
1. Verificar que Docker Desktop esté instalado
2. Reiniciar como administrador
3. Verificar que WSL2 esté habilitado (Windows 10/11)

### Error: "Puerto 3000 ocupado"
```bash
# Verificar qué usa el puerto
netstat -ano | findstr :3000

# Detener contenedores
docker compose down
```

### Error: "Aplicación no carga"
1. Verificar que el contenedor esté corriendo: `docker ps`
2. Verificar logs: `docker compose logs`
3. Esperar más tiempo (Rails puede tardar en cargar)

## 🔄 Actualizaciones

Para actualizar la aplicación:

1. Modifica el código Rails en `/docker/Aberturas/`
2. Reconstruye el instalador con `./build.ps1`
3. Incrementa la versión en `package.json`
4. Distribuye el nuevo instalador

## 📋 Lista de verificación antes de distribuir

- [ ] ✅ Probado en máquina Windows limpia
- [ ] ✅ Docker se instala correctamente
- [ ] ✅ Aplicación carga sin errores
- [ ] ✅ Iconos se muestran correctamente
- [ ] ✅ Instalador funciona sin privilegios elevados
- [ ] ✅ Desinstalador funciona correctamente
- [ ] ✅ Versión actualizada en package.json

## 🤝 Contribuir

Para contribuir al proyecto:

1. Fork del repositorio
2. Crear branch para feature: `git checkout -b feature/nueva-caracteristica`
3. Commit cambios: `git commit -am 'Agregar nueva característica'`
4. Push al branch: `git push origin feature/nueva-caracteristica`
5. Crear Pull Request

## 📄 Licencia

Este proyecto está bajo la licencia MIT. Ver `LICENSE` para más detalles.

---

**¡Listo! 🎉** Ya tenés un instalador profesional que maneja todo automáticamente.
