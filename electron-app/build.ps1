# Script PowerShell para construir el instalador ACMA en Windows
# Ejecutar como: .\build.ps1

param(
    [switch]$Clean = $false,
    [switch]$Verbose = $false
)

# Configurar colores
$ErrorActionPreference = "Stop"

function Write-Success {
    param([string]$Message)
    Write-Host "✅ $Message" -ForegroundColor Green
}

function Write-Error-Custom {
    param([string]$Message)
    Write-Host "❌ Error: $Message" -ForegroundColor Red
    exit 1
}

function Write-Warning-Custom {
    param([string]$Message)
    Write-Host "⚠️  $Message" -ForegroundColor Yellow
}

function Write-Info {
    param([string]$Message)
    Write-Host "ℹ️  $Message" -ForegroundColor Blue
}

Write-Host "🚀 Iniciando construcción del instalador ACMA..." -ForegroundColor Cyan

# Verificar que estamos en el directorio correcto
if (-not (Test-Path "package.json")) {
    Write-Error-Custom "Este script debe ejecutarse desde el directorio electron-app"
}

# Verificar que Node.js está instalado
try {
    $nodeVersion = node --version
    Write-Info "Node.js versión: $nodeVersion"
} catch {
    Write-Error-Custom "Node.js no está instalado. Por favor, instala Node.js primero."
}

# Verificar que npm está instalado
try {
    $npmVersion = npm --version
    Write-Info "npm versión: $npmVersion"
} catch {
    Write-Error-Custom "npm no está instalado. Por favor, instala npm primero."
}

# Verificar dependencias necesarias
Write-Info "Verificando dependencias..."

# Verificar que los iconos existen
if (-not (Test-Path "icon.png")) {
    Write-Warning-Custom "icon.png no encontrado. Se usará un icono por defecto."
}

if (-not (Test-Path "icon.ico")) {
    Write-Warning-Custom "icon.ico no encontrado. Se usará un icono por defecto."
}

# Verificar que docker-compose.yml existe
if (-not (Test-Path "../docker/docker-compose.yml")) {
    Write-Error-Custom "docker-compose.yml no encontrado en ../docker/"
}

# Limpiar builds anteriores si se solicita
if ($Clean -or (Test-Path "dist")) {
    Write-Info "Limpiando builds anteriores..."
    if (Test-Path "dist") {
        Remove-Item -Recurse -Force "dist"
    }
    if (Test-Path "node_modules/.cache") {
        Remove-Item -Recurse -Force "node_modules/.cache"
    }
    Write-Success "Limpieza completada"
}

# Instalar dependencias de Node.js
Write-Info "Instalando dependencias de Node.js..."
try {
    if ($Verbose) {
        npm install --verbose
    } else {
        npm install
    }
    Write-Success "Dependencias instaladas correctamente"
} catch {
    Write-Error-Custom "Error instalando dependencias de Node.js: $_"
}

# Verificar que electron-builder está instalado
try {
    npm list electron-builder | Out-Null
} catch {
    Write-Info "Instalando electron-builder..."
    try {
        npm install --save-dev electron-builder
    } catch {
        Write-Error-Custom "Error instalando electron-builder: $_"
    }
}

# Construir la aplicación
Write-Info "Construyendo aplicación Electron para Windows..."
try {
    if ($Verbose) {
        npm run build-win -- --verbose
    } else {
        npm run build-win
    }
    Write-Success "🎉 ¡Construcción completada exitosamente!"
} catch {
    Write-Error-Custom "Error construyendo la aplicación: $_"
}

# Mostrar información sobre los archivos generados
Write-Host ""
Write-Info "Archivos generados:"
if (Test-Path "dist") {
    Get-ChildItem -Path "dist" -Recurse -Include "*.exe", "*.msi" | ForEach-Object {
        $size = [math]::Round((Get-Item $_.FullName).Length / 1MB, 2)
        Write-Host "  📦 $($_.Name) ($size MB)" -ForegroundColor Green
    }
} else {
    Write-Warning-Custom "Directorio dist no encontrado"
}

# Mostrar ubicación de archivos
if (Test-Path "dist") {
    $distPath = Resolve-Path "dist"
    Write-Host ""
    Write-Info "Ubicación de archivos: $distPath"
}

# Instrucciones finales
Write-Host ""
Write-Host "🎯 Próximos pasos:" -ForegroundColor Green
Write-Host "1. Verifica que los archivos .exe se generaron en la carpeta 'dist/'"
Write-Host "2. Prueba el instalador en una máquina Windows limpia"
Write-Host "3. Asegúrate de que Docker Desktop se instale correctamente"
Write-Host ""
Write-Host "📋 Notas importantes:" -ForegroundColor Blue
Write-Host "• El instalador requerirá permisos de administrador"
Write-Host "• Docker Desktop se descargará automáticamente si no está instalado"
Write-Host "• Se recomienda probar en un entorno limpio antes de distribuir"
Write-Host ""
Write-Host "✨ ¡Instalador listo para distribuir!" -ForegroundColor Green

# Preguntar si quiere abrir la carpeta dist
$response = Read-Host "¿Deseas abrir la carpeta de distribución? (s/n)"
if ($response -eq "s" -or $response -eq "S" -or $response -eq "y" -or $response -eq "Y") {
    if (Test-Path "dist") {
        Invoke-Item "dist"
    }
}
