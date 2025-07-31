const { exec } = require('child_process');
const fs = require('fs');
const path = require('path');
const os = require('os');

class DockerInstaller {
  constructor() {
    this.dockerDesktopUrl = 'https://desktop.docker.com/win/main/amd64/Docker%20Desktop%20Installer.exe';
    this.installerPath = path.join(os.tmpdir(), 'Docker Desktop Installer.exe');
  }

  // Verificar si Docker está instalado
  async isDockerInstalled() {
    return new Promise((resolve) => {
      exec('docker --version', (error) => {
        resolve(!error);
      });
    });
  }

  // Verificar si Docker está corriendo
  async isDockerRunning() {
    return new Promise((resolve) => {
      exec('docker info', (error) => {
        resolve(!error);
      });
    });
  }

  // Descargar Docker Desktop Installer
  async downloadDockerInstaller() {
    const fetch = (...args) => import('node-fetch').then(({ default: fetch }) => fetch(...args));

    try {
      console.log('Descargando Docker Desktop Installer...');
      const response = await fetch(this.dockerDesktopUrl);

      if (!response.ok) {
        throw new Error(`Error descargando: ${response.statusText}`);
      }

      const fileStream = fs.createWriteStream(this.installerPath);
      response.body.pipe(fileStream);

      return new Promise((resolve, reject) => {
        fileStream.on('finish', () => {
          console.log('Descarga completada:', this.installerPath);
          resolve(this.installerPath);
        });
        fileStream.on('error', reject);
      });
    } catch (error) {
      throw new Error(`Error descargando Docker Desktop: ${error.message}`);
    }
  }

  // Instalar Docker Desktop
  async installDocker() {
    return new Promise((resolve, reject) => {
      const installCmd = `"${this.installerPath}" install --quiet --accept-license`;

      console.log('Instalando Docker Desktop...');
      exec(installCmd, { timeout: 300000 }, (error, stdout, stderr) => {
        if (error) {
          reject(new Error(`Error instalando Docker: ${error.message}`));
          return;
        }

        console.log('Docker Desktop instalado correctamente');
        resolve();
      });
    });
  }

  // Iniciar Docker Desktop
  async startDocker() {
    return new Promise((resolve) => {
      const startCmd = 'start "" "C:\\Program Files\\Docker\\Docker\\Docker Desktop.exe"';

      exec(startCmd, (error) => {
        if (error) {
          console.log('Intentando ruta alternativa...');
          exec('start "" "%PROGRAMFILES%\\Docker\\Docker\\Docker Desktop.exe"', (error2) => {
            resolve(!error2);
          });
        } else {
          resolve(true);
        }
      });
    });
  }

  // Esperar a que Docker esté listo
  async waitForDocker(maxWaitTime = 240000) {
    const startTime = Date.now();

    return new Promise((resolve) => {
      const checkInterval = setInterval(async () => {
        const isRunning = await this.isDockerRunning();

        if (isRunning) {
          clearInterval(checkInterval);
          console.log('Docker está listo');
          resolve(true);
        } else if (Date.now() - startTime > maxWaitTime) {
          clearInterval(checkInterval);
          console.log('Timeout esperando a Docker');
          resolve(false);
        }
      }, 3000);
    });
  }

  // Proceso completo de instalación
  async ensureDockerReady() {
    try {
      // Verificar si Docker ya está instalado
      const isInstalled = await this.isDockerInstalled();

      if (!isInstalled) {
        console.log('Docker no está instalado. Iniciando instalación...');

        // Descargar instalador
        await this.downloadDockerInstaller();

        // Instalar Docker
        await this.installDocker();

        console.log('Docker instalado. Puede ser necesario reiniciar el sistema.');
        return { installed: true, needsRestart: true };
      }

      // Verificar si Docker está corriendo
      const isRunning = await this.isDockerRunning();

      if (!isRunning) {
        console.log('Docker está instalado pero no está corriendo. Iniciando...');

        const started = await this.startDocker();

        if (started) {
          const ready = await this.waitForDocker();
          return { installed: true, running: ready, needsRestart: false };
        } else {
          return { installed: true, running: false, needsRestart: false };
        }
      }

      return { installed: true, running: true, needsRestart: false };

    } catch (error) {
      console.error('Error en ensureDockerReady:', error);
      return { installed: false, running: false, error: error.message };
    }
  }

  // Limpiar archivos temporales
  cleanup() {
    try {
      if (fs.existsSync(this.installerPath)) {
        fs.unlinkSync(this.installerPath);
        console.log('Archivos temporales eliminados');
      }
    } catch (error) {
      console.log('Error limpiando archivos temporales:', error.message);
    }
  }
}

module.exports = DockerInstaller;
