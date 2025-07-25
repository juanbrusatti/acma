# Iconos para ACMA

Para que el instalador funcione correctamente, necesitás crear los siguientes archivos de icono:

## Archivos necesarios:

1. **icon.png** - Icono principal de la aplicación (256x256 píxeles)
2. **icon.ico** - Icono para Windows (contiene múltiples tamaños: 16x16, 32x32, 48x48, 256x256)

## Cómo crear los iconos:

### Opción 1: Usando herramientas en línea
1. Ve a https://favicon.io/favicon-converter/
2. Sube una imagen de tu logo/marca
3. Descarga el .ico generado
4. Renómbralo como `icon.ico`

### Opción 2: Usando GIMP (gratuito)
1. Abre GIMP
2. Crea una imagen de 256x256 píxeles
3. Diseña tu icono
4. Exporta como PNG (icon.png)
5. Exporta como ICO (icon.ico)

### Opción 3: Usar PowerShell (Windows)
Si ya tenés un icon.png, podés convertirlo:

```powershell
# Instalar ImageMagick si no lo tenés
# Luego ejecutar:
magick icon.png -define icon:auto-resize=256,128,96,64,48,32,16 icon.ico
```

## Ubicación de los archivos:
- `/electron-app/icon.png`
- `/electron-app/icon.ico`

Los archivos deben estar en la carpeta electron-app para que electron-builder los encuentre.
