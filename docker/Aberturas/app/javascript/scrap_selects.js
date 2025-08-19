// scrap_selects.js
// Selects dinámicos para retazos

console.log('Cargando scrap_selects.js');

const SCRAP_OPTIONS = {
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

function updateThicknessOptions(typeSelect, thicknessSelect, colorSelect) {
  console.log('Actualizando opciones de espesor...');
  const tipo = typeSelect.value;
  console.log('Tipo seleccionado:', tipo);
  
  // Limpiar selects
  thicknessSelect.innerHTML = '<option value="">Seleccionar</option>';
  colorSelect.innerHTML = '<option value="">Seleccionar</option>';
  
  if (SCRAP_OPTIONS[tipo]) {
    console.log('Opciones encontradas para el tipo:', SCRAP_OPTIONS[tipo]);
    Object.keys(SCRAP_OPTIONS[tipo]).forEach(grosor => {
      const opt = document.createElement('option');
      opt.value = grosor;
      opt.textContent = grosor;
      thicknessSelect.appendChild(opt);
    });
  } else {
    console.log('No se encontraron opciones para el tipo:', tipo);
  }
}

function updateColorOptions(typeSelect, thicknessSelect, colorSelect) {
  console.log('Actualizando opciones de color...');
  const tipo = typeSelect.value;
  const grosor = thicknessSelect.value;
  console.log('Tipo y grosor seleccionados:', { tipo, grosor });
  
  colorSelect.innerHTML = '<option value="">Seleccionar</option>';
  
  if (SCRAP_OPTIONS[tipo] && SCRAP_OPTIONS[tipo][grosor]) {
    console.log('Colores disponibles:', SCRAP_OPTIONS[tipo][grosor]);
    SCRAP_OPTIONS[tipo][grosor].forEach(color => {
      const opt = document.createElement('option');
      opt.value = color;
      opt.textContent = color;
      colorSelect.appendChild(opt);
    });
  } else {
    console.log('No se encontraron colores para el tipo y grosor seleccionados');
  }
}

function updateScrapSelects(container) {
  console.log('Actualizando selects de retazos en contenedor:', container);
  
  const typeSelect = container.querySelector('.scrap-type-select');
  const thicknessSelect = container.querySelector('.scrap-thickness-select');
  const colorSelect = container.querySelector('.scrap-color-select');

  console.log('Selects encontrados:', { 
    typeSelect: typeSelect ? 'Encontrado' : 'No encontrado',
    thicknessSelect: thicknessSelect ? 'Encontrado' : 'No encontrado',
    colorSelect: colorSelect ? 'Encontrado' : 'No encontrado'
  });

  if (!typeSelect || !thicknessSelect || !colorSelect) {
    console.error('No se encontraron todos los selects necesarios');
    return;
  }

  // Configurar eventos
  typeSelect.addEventListener('change', () => {
    console.log('Cambio detectado en el select de tipo');
    updateThicknessOptions(typeSelect, thicknessSelect, colorSelect);
    updateColorOptions(typeSelect, thicknessSelect, colorSelect);
  });
  
  thicknessSelect.addEventListener('change', () => {
    console.log('Cambio detectado en el select de espesor');
    updateColorOptions(typeSelect, thicknessSelect, colorSelect);
  });

  // Actualizar opciones iniciales
  updateThicknessOptions(typeSelect, thicknessSelect, colorSelect);
  updateColorOptions(typeSelect, thicknessSelect, colorSelect);
  
  console.log('Selects de retazos configurados correctamente');
}

function setupAllScrapSelects() {
  console.log('Configurando todos los selects de retazos...');
  const containers = document.querySelectorAll('.scrap-fields');
  console.log('Contenedores encontrados:', containers.length);
  containers.forEach(updateScrapSelects);
}

// Exportar al ámbito global
window.updateScrapSelects = updateScrapSelects;
window.setupAllScrapSelects = setupAllScrapSelects;

// Inicializar automáticamente si el archivo se carga después de que el DOM esté listo
if (document.readyState === 'complete' || document.readyState === 'interactive') {
  setupAllScrapSelects();
}
