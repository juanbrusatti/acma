// glasscutting_selects.js

export const GLASS_OPTIONS = {
  LAM: {
    "3+3": ["INC", "BLS"],
    "4+4": ["INC"],
    "5+5": ["INC"]
  },
  FLO: {
    "5mm": ["GRS", "BRC", "INC"]
  },
  COL: {
    "4+4": ["STB", "STG", "NTR"]
  }
};

export function updateGlassSelects(container) {
  const typeSelect = container.querySelector('.glass-type-select');
  const thicknessSelect = container.querySelector('.glass-thickness-select');
  const colorSelect = container.querySelector('.glass-color-select');

  if (!typeSelect || !thicknessSelect || !colorSelect) return;

  // Limpiar y llenar grosores según tipo seleccionado
  function updateThicknessOptions() {
    const tipo = typeSelect.value;
    thicknessSelect.innerHTML = '<option value="">Seleccionar</option>';
    colorSelect.innerHTML = '<option value="">Seleccionar</option>';

    if (GLASS_OPTIONS[tipo]) {
      const grosores = Object.keys(GLASS_OPTIONS[tipo]);
      grosores.forEach(grosor => {
        const opt = document.createElement('option');
        opt.value = grosor;
        opt.textContent = grosor;
        thicknessSelect.appendChild(opt);
      });
    }
  }

  // Limpiar y llenar colores según tipo y grosor seleccionados
  function updateColorOptions() {
    const tipo = typeSelect.value;
    const grosor = thicknessSelect.value;
    colorSelect.innerHTML = '<option value="">Seleccionar</option>';

    if (GLASS_OPTIONS[tipo] && GLASS_OPTIONS[tipo][grosor]) {
      GLASS_OPTIONS[tipo][grosor].forEach(color => {
        const opt = document.createElement('option');
        opt.value = color;
        opt.textContent = color;
        colorSelect.appendChild(opt);
      });
    }
  }

  // Inicializar en caso de tener valores preseleccionados
  updateThicknessOptions();
  updateColorOptions();

  // Listeners
  typeSelect.addEventListener('change', () => {
    updateThicknessOptions();
    updateColorOptions(); // Opcional: si querés limpiar colores al cambiar tipo
  });

  thicknessSelect.addEventListener('change', updateColorOptions);
}

export function setupAllGlassSelects() {
  document.querySelectorAll('.glasscutting-fields').forEach(updateGlassSelects);
}