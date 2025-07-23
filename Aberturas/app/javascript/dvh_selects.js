// dvh_selects.js

// Glass options for DVH (reuse or adapt as needed)
export const GLASS_OPTIONS = {
  "LAM": {
    grosores: ["3+3", "4+4", "5+5"],
    colores: ["INC", "esmerilado"]
  },
  "FLO": {
    grosores: ["5mm"],
    colores: ["INC", "gris", "bronce"]
  },
  "COL": {
    grosores: ["4+4"],
    colores: ["INC"]
  }
};

export function updateDvhGlassSelects(container, prefix) {
  // prefix: 'glasscutting1' or 'glasscutting2'
  const typeSelect = container.querySelector(`.${prefix}-type-select`);
  const thicknessSelect = container.querySelector(`.${prefix}-thickness-select`);
  const colorSelect = container.querySelector(`.${prefix}-color-select`);

  if (!typeSelect || !thicknessSelect || !colorSelect) return;

  function fillOptions() {
    const tipo = typeSelect.value;
    thicknessSelect.innerHTML = '<option value="">Seleccionar</option>';
    colorSelect.innerHTML = '<option value="">Seleccionar</option>';
    if (GLASS_OPTIONS[tipo]) {
      GLASS_OPTIONS[tipo].grosores.forEach(g => {
        const opt = document.createElement('option');
        opt.value = g;
        opt.textContent = g;
        thicknessSelect.appendChild(opt);
      });
      GLASS_OPTIONS[tipo].colores.forEach(c => {
        const opt = document.createElement('option');
        opt.value = c;
        opt.textContent = c;
        colorSelect.appendChild(opt);
      });
    }
  }

  // Initialize based on current value
  fillOptions();

  // Update thickness and color when type changes
  typeSelect.addEventListener('change', fillOptions);
}

export function setupAllDvhGlassSelects() {
  document.querySelectorAll('.dvh-fields').forEach(container => {
    updateDvhGlassSelects(container, 'glasscutting1');
    updateDvhGlassSelects(container, 'glasscutting2');
  });
}
