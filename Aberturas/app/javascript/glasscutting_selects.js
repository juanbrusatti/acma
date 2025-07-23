// glasscutting_selects.js

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

export function updateGlassSelects(container) {
  const typeSelect = container.querySelector('.glass-type-select');
  const thicknessSelect = container.querySelector('.glass-thickness-select');
  const colorSelect = container.querySelector('.glass-color-select');

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

  // Inicializar según valor actual
  fillOptions();

  // Cuando cambia el tipo, actualizar grosores y colores
  typeSelect.addEventListener('change', fillOptions);
}

export function setupAllGlassSelects() {
  document.querySelectorAll('.glasscutting-fields').forEach(updateGlassSelects);
}