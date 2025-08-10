# Configuración del Servidor para ACMA - Sistema de Aberturas

Este documento explica cómo configurar el servidor que alojará la aplicación Rails para que los clientes con el instalador de escritorio puedan conectarse.

## Requisitos del Servidor

1. Ruby 3.x (recomendado: 3.2.0 o superior)
2. Rails 7.x
3. Base de datos SQLite (configurada por defecto)

## Configuración de Red

El servidor debe estar configurado en la misma red local que los clientes:

- IP predeterminada: `192.168.68.69`
- Puerto predeterminado: `3000`

> **Importante**: Si necesita cambiar la IP o el puerto del servidor, deberá modificar el archivo `main.js` de la aplicación Electron y recompilar el instalador.

## Instrucciones de Instalación del Servidor

1. Clone este repositorio en el servidor
2. Navegue a la carpeta `docker/Aberturas`
3. Ejecute los siguientes comandos:

```bash
bundle install
rails db:setup
rails server -b 0.0.0.0 -p 3000
```

## Verificación

Para verificar que el servidor está funcionando correctamente, abra un navegador y navegue a `http://192.168.1.100:3000`

## Configuración para Producción

Para un entorno de producción, considere:

1. Configurar un servicio systemd para mantener el servidor activo
2. Usar un servidor web como Nginx como proxy inverso
3. Configurar SSL para una conexión segura

## Solución de Problemas

Si los clientes no pueden conectarse:

1. Verifique que el firewall del servidor permite conexiones al puerto 3000
2. Confirme que el servidor está en ejecución: `ps aux | grep rails`
3. Verifique que la IP del servidor es correcta y está disponible en la red local
