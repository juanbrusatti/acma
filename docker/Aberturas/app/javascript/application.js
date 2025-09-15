import "@hotwired/turbo-rails"
import "controllers"
import "projects_form"
import "projects_inline_edit"
import "glass_prices_calculator"
import "supply_editing"
import "preview_pdf"
import { setupAllGlassplateSelects } from "glassplate_selects"
import { setupAllScrapSelects } from "scrap_selects"
import "delete_confirmation"
import "quantity_editor"
import "glassplate_inline_edit"
import "scrap_inline_edit"

document.addEventListener("turbo:load", () => {
	// Inicializar selects dinámicos para glassplates y scraps
	setupAllGlassplateSelects();
	setupAllScrapSelects();
	
	// Exponer funciones para depuración manual
	window.setupAllScrapSelects = setupAllScrapSelects;
	window.setupAllGlassplateSelects = setupAllGlassplateSelects;
});