const { app, BrowserWindow, dialog, ipcMain } = require("electron");
const { exec } = require("child_process");
const path = require("path");
const fs = require("fs");
const os = require("os");
const DockerInstaller = require("./docker-installer");

let mainWindow;
let dockerComposePath;
let dockerInstaller;

// Determinar la ruta correcta del docker-compose según si es desarrollo o producción
function getDockerComposePath() {
  const isDev = process.env.NODE_ENV === "development";

  if (isDev) {
    return path.join(__dirname, "../docker/docker-compose.yml");
  } else {
    // En producción, los archivos están en extraResources
    return path.join(process.resourcesPath, "docker", "docker-compose.yml");
  }
}

// Función para mostrar ventana de progreso con HTML personalizado
function showProgressWindow(title, message, canCancel = false) {
  const progressWindow = new BrowserWindow({
    width: 500,
    height: 300,
    parent: mainWindow,
    modal: true,
    show: false,
    resizable: false,
    frame: true,
    webPreferences: {
      nodeIntegration: true,
      contextIsolation: false
    }
  });

  const htmlContent = `
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="UTF-8">
      <title>${title}</title>
      <style>
        body {
          font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
          margin: 0;
          padding: 30px;
          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
          color: white;
          text-align: center;
          min-height: 240px;
          display: flex;
          flex-direction: column;
          justify-content: center;
        }
        .container {
          background: rgba(255, 255, 255, 0.1);
          border-radius: 15px;
          padding: 30px;
          backdrop-filter: blur(10px);
          box-shadow: 0 8px 32px rgba(0, 0, 0, 0.3);
        }
        h2 {
          margin-top: 0;
          font-size: 24px;
          font-weight: 300;
        }
        .message {
          font-size: 16px;
          margin: 20px 0;
          line-height: 1.5;
        }
        .spinner {
          margin: 20px auto;
          width: 40px;
          height: 40px;
          border: 4px solid rgba(255, 255, 255, 0.3);
          border-top: 4px solid white;
          border-radius: 50%;
          animation: spin 1s linear infinite;
        }
        @keyframes spin {
          0% { transform: rotate(0deg); }
          100% { transform: rotate(360deg); }
        }
        .cancel-btn {
          background: rgba(255, 255, 255, 0.2);
          border: 1px solid rgba(255, 255, 255, 0.3);
          color: white;
          padding: 10px 20px;
          border-radius: 5px;
          cursor: pointer;
          font-size: 14px;
          margin-top: 20px;
          transition: background 0.3s;
        }
        .cancel-btn:hover {
          background: rgba(255, 255, 255, 0.3);
        }
      </style>
    </head>
    <body>
      <div class="container">
        <h2>${title}</h2>
        <div class="spinner"></div>
        <div class="message" id="message">${message}</div>
        ${canCancel ? '<button class="cancel-btn" onclick="require(\'electron\').ipcRenderer.send(\'cancel-operation\')">Cancelar</button>' : ''}
      </div>
    </body>
    </html>
  `;

  progressWindow.loadURL(
    `data:text/html;charset=utf-8,${encodeURIComponent(htmlContent)}`
  );
  progressWindow.show();

  if (canCancel) {
    ipcMain.once('cancel-operation', () => {
      progressWindow.close();
    });
  }

  return progressWindow;
}

// Función para actualizar el mensaje de progreso
function updateProgressMessage(window, newMessage) {
  if (window && !window.isDestroyed()) {
    window.webContents.executeJavaScript(`
      document.getElementById('message').innerHTML = '${newMessage}';
    `);
  }
}

// Función para iniciar el contenedor
function startContainer() {
  return new Promise((resolve, reject) => {
    const dockerCmd = `docker compose -f "${dockerComposePath}" up -d`;

    console.log("Ejecutando:", dockerCmd);

    exec(dockerCmd, { cwd: path.dirname(dockerComposePath) }, (err, stdout, stderr) => {
      if (err) {
        console.error(`Error arrancando contenedor: ${stderr}`);
        reject(new Error(`Error iniciando contenedor: ${stderr || err.message}`));
        return;
      }
      console.log("Contenedor iniciado correctamente:", stdout);
      resolve();
    });
  });
}

// Función para verificar si la aplicación Rails está lista
function waitForRailsApp(maxWait = 60000) {
  return new Promise((resolve) => {
    const startTime = Date.now();

    const checkInterval = setInterval(() => {
      exec('curl -f http://localhost:3000', (error) => {
        if (!error) {
          clearInterval(checkInterval);
          resolve(true);
        } else if (Date.now() - startTime > maxWait) {
          clearInterval(checkInterval);
          resolve(false);
        }
      });
    }, 2000);
  });
}

// Función para crear la ventana principal
function createWindow() {
  mainWindow = new BrowserWindow({
    width: 1200,
    height: 800,
    icon: path.join(__dirname, "icon.png"),
    show: false,
    webPreferences: {
      nodeIntegration: false,
      contextIsolation: true,
      webSecurity: false // Permitir cargar localhost
    }
  });

  // Mostrar ventana cuando esté lista
  mainWindow.once('ready-to-show', () => {
    mainWindow.show();
  });

  mainWindow.loadURL("http://localhost:3000");

  mainWindow.on("closed", () => {
    // Apagar contenedor al cerrar
    if (dockerComposePath) {
      exec(`docker compose -f "${dockerComposePath}" down`, (err) => {
        if (err) {
          console.error("Error deteniendo contenedor:", err);
        } else {
          console.log("Contenedor detenido correctamente");
        }
      });
    }
  });

  // Manejar errores de carga
  mainWindow.webContents.on('did-fail-load', (event, errorCode, errorDescription) => {
    console.error("Error cargando aplicación:", errorDescription);

    if (errorCode === -102) { // ERR_CONNECTION_REFUSED
      dialog.showErrorBox(
        "Error de conexión",
        "No se pudo conectar a la aplicación. Verifica que Docker esté funcionando correctamente."
      );
    }
  });
}

// Función principal de inicialización
async function initializeApp() {
  dockerComposePath = getDockerComposePath();
  dockerInstaller = new DockerInstaller();

  let progressWindow = null;

  try {
    // Mostrar ventana de inicialización
    progressWindow = showProgressWindow(
      "Iniciando ACMA",
      "Verificando dependencias del sistema...",
      false
    );

    // Verificar y configurar Docker
    updateProgressMessage(progressWindow, "Verificando Docker Desktop...");

    const dockerStatus = await dockerInstaller.ensureDockerReady();

    if (dockerStatus.error) {
      throw new Error(`Error con Docker: ${dockerStatus.error}`);
    }

    if (dockerStatus.needsRestart) {
      progressWindow.close();

      const result = await dialog.showMessageBox(null, {
        type: "warning",
        buttons: ["Reiniciar ahora", "Reiniciar más tarde"],
        defaultId: 0,
        title: "Reinicio requerido",
        message: "Docker Desktop se ha instalado correctamente",
        detail: "Se requiere un reinicio del sistema para completar la instalación. ¿Deseas reiniciar ahora?"
      });

      if (result.response === 0) {
        // Reiniciar sistema
        exec('shutdown /r /t 5', (err) => {
          if (err) {
            dialog.showErrorBox("Error", "No se pudo reiniciar automáticamente. Por favor, reinicia manualmente.");
          }
        });
      } else {
        dialog.showMessageBox(null, {
          type: "info",
          title: "Recordatorio",
          message: "Recuerda reiniciar tu sistema antes de usar ACMA nuevamente."
        });
      }

      app.quit();
      return;
    }

    if (!dockerStatus.running) {
      throw new Error("Docker Desktop no se pudo iniciar. Por favor, inicia Docker Desktop manualmente.");
    }

    // Docker está listo, iniciar contenedor
    updateProgressMessage(progressWindow, "Iniciando contenedor de la aplicación...");

    await startContainer();

    // Esperar a que Rails esté listo
    updateProgressMessage(progressWindow, "Esperando a que la aplicación esté lista...");

    const railsReady = await waitForRailsApp();

    if (!railsReady) {
      throw new Error("La aplicación Rails no respondió en el tiempo esperado.");
    }

    // Cerrar ventana de progreso y abrir aplicación
    progressWindow.close();
    progressWindow = null;

    createWindow();

  } catch (error) {
    console.error("Error inicializando aplicación:", error);

    if (progressWindow) {
      progressWindow.close();
    }

    const result = await dialog.showMessageBox(null, {
      type: "error",
      buttons: ["Reintentar", "Salir"],
      defaultId: 1,
      title: "Error de inicialización",
      message: "Error iniciando ACMA",
      detail: error.message
    });

    if (result.response === 0) {
      // Reintentar
      setTimeout(() => initializeApp(), 2000);
    } else {
      app.quit();
    }
  } finally {
    // Limpiar archivos temporales
    if (dockerInstaller) {
      dockerInstaller.cleanup();
    }
  }
}

// Configuración de la aplicación
app.whenReady().then(initializeApp);

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') {
    app.quit();
  }
});

app.on('activate', () => {
  if (BrowserWindow.getAllWindows().length === 0) {
    initializeApp();
  }
});

// Prevenir que se abran múltiples instancias
const gotTheLock = app.requestSingleInstanceLock();

if (!gotTheLock) {
  app.quit();
} else {
  app.on('second-instance', () => {
    if (mainWindow) {
      if (mainWindow.isMinimized()) mainWindow.restore();
      mainWindow.focus();
    }
  });
}
