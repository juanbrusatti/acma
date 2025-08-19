// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"
import "projects_form"
import "projects_inline_edit"
import "glass_prices_calculator"
import "supply_editing"
import "preview_pdf"
import "scrap_selects"
import "glassplate_selects"

// Función para inicializar los selects de retazos
function initScrapSelects() {
  const container = document.querySelector('.scrap-fields');
  if (!container) return;
  
  console.log('Inicializando selects de retazos...');
  
  // Usar window para acceder a las funciones exportadas globalmente
  if (window.setupAllScrapSelects) {
    window.setupAllScrapSelects();
  } else {
    console.error('setupAllScrapSelects no está definido');
  }
}

// Inicializar cuando el DOM esté listo
document.addEventListener('DOMContentLoaded', () => {
  console.log('DOM cargado');
  initScrapSelects();
});

// Inicializar con Turbo
document.addEventListener('turbo:load', () => {
  console.log('Turbo cargado');
  initScrapSelects();
});

// Inicializar ahora mismo si el DOM ya está listo
if (document.readyState === 'complete' || document.readyState === 'interactive') {
  initScrapSelects();
}