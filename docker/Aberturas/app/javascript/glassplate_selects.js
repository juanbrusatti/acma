// glassplate_selects.js
// Selects dinámicos para planchas de vidrio
// Reutiliza el módulo común glass_selects_common.js

import { updateGlassSelects } from "glass_selects_common"

export function updateGlassplateSelects(container) {
  const selectors = {
    typeSelector: '.glassplate-type-select',
    thicknessSelector: '.glassplate-thickness-select',
    colorSelector: '.glassplate-color-select'
  };
  
  updateGlassSelects(container, selectors);
}

export function setupAllGlassplateSelects() {
  document.querySelectorAll('.glassplate-fields').forEach(updateGlassplateSelects);
}
