#!/bin/bash

# Script para construir el instalador completo de ACMA
# Este script automatiza todo el proceso de construcción

echo "🚀 Iniciando construcción del instalador ACMA..."

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función para mostrar errores
error() {
    echo -e "${RED}❌ Error: $1${NC}"
    exit 1
}

# Función para mostrar éxito
success() {
    echo -e "${GREEN}✅ $1${NC}"
}

# Función para mostrar advertencias
warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Función para mostrar información
info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Verificar que estamos en el directorio correcto
if [ ! -f "package.json" ]; then
    error "Este script debe ejecutarse desde el directorio electron-app"
fi

# Verificar que Node.js está instalado
if ! command -v node &> /dev/null; then
    error "Node.js no está instalado. Por favor, instala Node.js primero."
fi

# Verificar que npm está instalado
if ! command -v npm &> /dev/null; then
    error "npm no está instalado. Por favor, instala npm primero."
fi

# Verificar dependencias necesarias
info "Verificando dependencias..."

# Verificar que los iconos existen
if [ ! -f "icon.png" ]; then
    warning "icon.png no encontrado. Se usará un icono por defecto."
fi

if [ ! -f "icon.ico" ]; then
    warning "icon.ico no encontrado. Se usará un icono por defecto."
fi

# Verificar que docker-compose.yml existe
if [ ! -f "../docker/docker-compose.yml" ]; then
    error "docker-compose.yml no encontrado en ../docker/"
fi

# Instalar dependencias de Node.js
info "Instalando dependencias de Node.js..."
npm install || error "Error instalando dependencias de Node.js"

success "Dependencias instaladas correctamente"

# Limpiar builds anteriores
info "Limpiando builds anteriores..."
rm -rf dist/
rm -rf node_modules/.cache/
success "Limpieza completada"

# Verificar que electron-builder está instalado
if ! npm list electron-builder &> /dev/null; then
    info "Instalando electron-builder..."
    npm install --save-dev electron-builder || error "Error instalando electron-builder"
fi

# Construir la aplicación
info "Construyendo aplicación Electron..."
npm run build-win || error "Error construyendo la aplicación"

success "🎉 ¡Construcción completada exitosamente!"

# Mostrar información sobre los archivos generados
echo ""
info "Archivos generados:"
if [ -d "dist" ]; then
    find dist -name "*.exe" -o -name "*.msi" | while read file; do
        size=$(du -h "$file" | cut -f1)
        echo -e "  📦 ${file} (${size})"
    done
else
    warning "Directorio dist no encontrado"
fi

# Instrucciones finales
echo ""
echo -e "${GREEN}🎯 Próximos pasos:${NC}"
echo "1. Verifica que los archivos .exe se generaron en la carpeta 'dist/'"
echo "2. Prueba el instalador en una máquina Windows limpia"
echo "3. Asegúrate de que Docker Desktop se instale correctamente"
echo ""
echo -e "${BLUE}📋 Notas importantes:${NC}"
echo "• El instalador requerirá permisos de administrador"
echo "• Docker Desktop se descargará automáticamente si no está instalado"
echo "• Se recomienda probar en un entorno limpio antes de distribuir"
echo ""
echo -e "${GREEN}✨ ¡Instalador listo para distribuir!${NC}"
