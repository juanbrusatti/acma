const { app, BrowserWindow, dialog } = require("electron");
const path = require("path");

const IP = "192.168.68.69"; // Cambia esto a la IP de tu servidor
const PORT = "3000"; // Puerto del servidor

// --- CONFIGURACIÓN PRINCIPAL ---
const SERVER_URL = `http://${IP}:${PORT}`;

let mainWindow;

function createWindow() {
  mainWindow = new BrowserWindow({
    width: 1200,
    height: 800,
    icon: path.join(__dirname, "icon.png"), // Asume que el ícono sigue en la misma carpeta
    show: false, // Buena práctica para evitar un parpadeo inicial
    webPreferences: {
      // Estas son buenas prácticas de seguridad. No necesitás nodeIntegration.
      contextIsolation: true,
      // webSecurity se puede dejar en 'true' (el valor por defecto) para mayor seguridad.
      // Quítalo o ponlo en 'true'.
    },
  });

  // Mostrar la ventana cuando esté lista para mostrarse
  mainWindow.once("ready-to-show", () => {
    mainWindow.show();
  });

  // Cargar directamente la URL del servidor
  mainWindow.loadURL(SERVER_URL);

  // Manejar errores de carga de la página
  mainWindow.webContents.on(
    "did-fail-load",
    (event, errorCode, errorDescription) => {
      console.error(`Error cargando la URL ${SERVER_URL}: ${errorDescription}`);

      // Ya no es un error de Docker, es un error de conexión.
      dialog.showErrorBox(
        "Error de Conexión",
        `No se pudo conectar al servidor en ${SERVER_URL}.\n\n` +
          "Por favor, verifica lo siguiente:\n" +
          "1. Tu conexión a internet.\n" +
          "2. Que el servidor esté funcionando correctamente."
      );
    }
  );

  // El evento 'closed' ya no necesita hacer nada con Docker.
  mainWindow.on("closed", () => {
    mainWindow = null;
  });
}

// --- CICLO DE VIDA DE LA APLICACIÓN ---

// Prevenir que se abran múltiples instancias de la app
const gotTheLock = app.requestSingleInstanceLock();
if (!gotTheLock) {
  app.quit();
} else {
  app.on("second-instance", () => {
    // Si alguien intenta abrir una segunda instancia, enfoca nuestra ventana principal
    if (mainWindow) {
      if (mainWindow.isMinimized()) mainWindow.restore();
      mainWindow.focus();
    }
  });
}

// Iniciar la aplicación cuando Electron esté listo
app.whenReady().then(createWindow);

// Salir de la app cuando todas las ventanas estén cerradas (en Windows y Linux)
app.on("window-all-closed", () => {
  if (process.platform !== "darwin") {
    app.quit();
  }
});

app.on("activate", () => {
  // En macOS, recrear la ventana si se hace clic en el ícono del dock
  if (BrowserWindow.getAllWindows().length === 0) {
    createWindow();
  }
});
