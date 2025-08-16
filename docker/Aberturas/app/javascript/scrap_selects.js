// scrap_selects.js
// Selects dinámicos para retazos, igual que glassplates

export const SCRAP_OPTIONS = {
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

export function updateScrapSelects(container) {
  const typeSelect = container.querySelector('.scrap-type-select');
  const thicknessSelect = container.querySelector('.scrap-thickness-select');
  const colorSelect = container.querySelector('.scrap-color-select');

  if (!typeSelect || !thicknessSelect || !colorSelect) return;

  function updateThicknessOptions() {
    const tipo = typeSelect.value;
    thicknessSelect.innerHTML = '<option value="">Seleccionar</option>';
    colorSelect.innerHTML = '<option value="">Seleccionar</option>';
    if (SCRAP_OPTIONS[tipo]) {
      Object.keys(SCRAP_OPTIONS[tipo]).forEach(grosor => {
        const opt = document.createElement('option');
        opt.value = grosor;
        opt.textContent = grosor;
        thicknessSelect.appendChild(opt);
      });
    }
  }

  function updateColorOptions() {
    const tipo = typeSelect.value;
    const grosor = thicknessSelect.value;
    colorSelect.innerHTML = '<option value="">Seleccionar</option>';
    if (SCRAP_OPTIONS[tipo] && SCRAP_OPTIONS[tipo][grosor]) {
      SCRAP_OPTIONS[tipo][grosor].forEach(color => {
        const opt = document.createElement('option');
        opt.value = color;
        opt.textContent = color;
        colorSelect.appendChild(opt);
      });
    }
  }

  updateThicknessOptions();
  updateColorOptions();

  typeSelect.addEventListener('change', () => {
    updateThicknessOptions();
    updateColorOptions();
  });
  thicknessSelect.addEventListener('change', updateColorOptions);
}

export function setupAllScrapSelects() {
  document.querySelectorAll('.scrap-fields').forEach(updateScrapSelects);
}
