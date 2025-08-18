// scraps_form.js
import { setupAllScrapSelects, updateScrapSelects } from "scrap_selects";

// Función para inicializar los selectores
export function initScrapsForm() {
  const container = document.querySelector('.scrap-fields');
  if (!container) return;
  
  // Inicializar los selectores
  updateScrapSelects(container);
  
  // Forzar la actualización cuando cambia el tipo
  const typeSelect = container.querySelector('.scrap-type-select');
  if (typeSelect) {
    // Disparar evento change para cargar los espesores
    const event = new Event('change');
    typeSelect.dispatchEvent(event);
  }
}

// Inicializar solo si estamos en una página que contiene el formulario de scraps
if (document.querySelector('.scrap-fields')) {
  // Inicializar en la carga inicial
  document.addEventListener('DOMContentLoaded', initScrapsForm);
  
  // Inicializar con Turbo
  document.addEventListener('turbo:load', initScrapsForm);
  document.addEventListener('turbo:render', initScrapsForm);
  
  // Inicializar ahora mismo si el DOM ya está listo
  if (document.readyState === 'complete' || document.readyState === 'interactive') {
    initScrapsForm();
  }
}
