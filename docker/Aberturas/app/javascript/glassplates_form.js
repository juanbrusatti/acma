// glassplates_form.js
import { setupAllGlassplateSelects, updateGlassplateSelects } from "glassplate_selects";

// Función para inicializar los selectores
export function initGlassplatesForm() {
  const container = document.querySelector('.glassplate-fields');
  if (!container) return;
  
  // Inicializar los selectores
  updateGlassplateSelects(container);
  
  // Forzar la actualización cuando cambia el tipo
  const typeSelect = container.querySelector('.glassplate-type-select');
  if (typeSelect) {
    // Disparar evento change para cargar los espesores
    const event = new Event('change');
    typeSelect.dispatchEvent(event);
  }
}

// Inicializar solo si estamos en una página que contiene el formulario de glassplates
if (document.querySelector('.glassplate-fields')) {
  // Inicializar en la carga inicial
  document.addEventListener('DOMContentLoaded', initGlassplatesForm);
  
  // Inicializar con Turbo
  document.addEventListener('turbo:load', initGlassplatesForm);
  document.addEventListener('turbo:render', initGlassplatesForm);
  
  // Inicializar ahora mismo si el DOM ya está listo
  if (document.readyState === 'complete' || document.readyState === 'interactive') {
    initGlassplatesForm();
  }
}
