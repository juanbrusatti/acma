// scrap_selects.js
// Selects dinámicos para retazos
// Reutiliza el módulo común glass_selects_common.js

import { updateGlassSelects } from "glass_selects_common"

export function updateScrapSelects(container) {
  const selectors = {
    typeSelector: '.scrap-type-select',
    thicknessSelector: '.scrap-thickness-select',
    colorSelector: '.scrap-color-select'
  };
  
  updateGlassSelects(container, selectors);
}

export function setupAllScrapSelects() {
  document.querySelectorAll('.scrap-fields').forEach(updateScrapSelects);
}
