# Instalación de Docker Engine en Windows Server

Este documento explica cómo instalar **Docker Engine** en Windows Server y levantar los contenedores de la aplicación Rails.

---

## 1️⃣ Requisitos previos

- Windows Server 2016, 2019 o 2022.  
- Acceso a **PowerShell con permisos de Administrador**.  
- Conexión a internet para descargar paquetes.

---

## 2️⃣ Habilitar contenedores y dependencias

1. Abrir **PowerShell como Administrador**.  
2. Instalar la función de contenedores de Windows:

```powershell
Install-WindowsFeature -Name containers -IncludeAllSubFeature -IncludeManagementTools

3. Reiniciar el servidor si es necesario:

```powershell
Restart-Computer -Force
``` 

4. Abrir PowerShell como Administrador nuevamente.
   Instalar: ``` Install-Module -Name DockerMsftProvider -Repository PSGallery -Force ```

5. Instalar Docker Engine:
   ``` Install-Package -Name docker -ProviderName DockerMsftProvider -Force ```

6. Reiniciar el servidor:
   ``` Restart-Computer -Force ```

7. Verificar la instalación:
   ``` docker version ```
   ``` docker info ```

8. Si todo funciona bien, Docker Engine está instalado correctamente y utilizamos el start_server_ws.bat para levantar los contenedores.