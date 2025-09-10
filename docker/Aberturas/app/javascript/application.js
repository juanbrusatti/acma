// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"
import "projects_form"
import "projects_inline_edit"
import "glass_prices_calculator"
import "supply_editing"
import "preview_pdf"
import "glassplate_selects"
import "scrap_selects"
import "confirmations"


document.addEventListener("turbo:load", () => {
	// Inicializar selects automáticamente
	setupAllGlassplateSelects();
	setupAllScrapSelects();
	
	// Exponer funciones para depuración manual
	window.setupAllScrapSelects = setupAllScrapSelects;
	window.updateScrapSelects = updateScrapSelects;
	window.setupAllGlassplateSelects = setupAllGlassplateSelects;
	window.updateGlassplateSelects = updateGlassplateSelects;
});