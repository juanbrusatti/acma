// scraps_form.js
import { setupAllScrapSelects, updateScrapSelects } from "./scrap_selects";


// Función para inicializar los selectores
export function initScrapsForm() {
  // Buscar el contenedor del formulario
  const container = document.querySelector('.scrap-fields');

  if (!container) {
    return;
  }
  
  // Verificar si los selects existen
  const typeSelect = container.querySelector('.scrap-type-select');
  const thicknessSelect = container.querySelector('.scrap-thickness-select');
  const colorSelect = container.querySelector('.scrap-color-select');
  
  if (!typeSelect || !thicknessSelect || !colorSelect) {
    return;
  }
  
  // Inicializar los selectores
  updateScrapSelects(container);
  
  // Forzar la actualización cuando cambia el tipo
  const event = new Event('change');
  typeSelect.dispatchEvent(event);
}

// Inicializar cuando el DOM esté listo
function initialize() {
  if (document.querySelector('.scrap-fields')) {
    initScrapsForm();
  }
}

// Inicializar en diferentes momentos del ciclo de vida de la página
if (document.readyState === 'loading') {
  // El DOM aún no está completamente cargado
  document.addEventListener('DOMContentLoaded', initialize);
} else {
  // El DOM ya está cargado
  initialize();
}

// Inicializar con Turbo
document.addEventListener('turbo:load', initialize);
document.addEventListener('turbo:render', initialize);
document.addEventListener('turbo:frame-render', initialize);

// Exportar para depuración
window.initScrapsForm = initScrapsForm;
