// scrap_inline_edit.js
// Módulo para edición inline de retazos de vidrio
// Versión simplificada sin imports externos

// GLASS_OPTIONS - Opciones reales de glass_selects_common.js
const GLASS_OPTIONS = {
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

class ScrapInlineEditor {
  constructor() {
    this.glassOptions = GLASS_OPTIONS;
    this.editingRow = null;
    this.originalData = {};
    this.setupEventListeners();
    console.log('ScrapInlineEditor initialized'); // Debug
  }

  setupEventListeners() {
    // Bindear botones cuando se carga la página
    document.addEventListener('turbo:load', () => {
      this.bindEditButtons();
    });

    // También bindear inmediatamente si ya está cargado
    this.bindEditButtons();
  }

  bindEditButtons() {
    document.querySelectorAll('.edit-scrap-btn').forEach(btn => {
      // Remover listeners existentes para evitar duplicados
      btn.removeEventListener('click', this.handleEditClick);
      btn.addEventListener('click', (e) => this.handleEditClick(e), true); // true = capture phase
    });
  }

  handleEditClick(e) {
    e.preventDefault();
    e.stopPropagation(); // Evitar que otros sistemas capturen el evento
    console.log('🎯 Scrap edit button clicked - OUR SYSTEM'); // Debug

    const row = e.target.closest('tr');
    console.log('Row found:', row); // Debug

    if (!row) {
      console.error('❌ No se pudo encontrar la fila (tr)');
      return;
    }

    this.startEdit(row);
  }

  startEdit(row) {
    if (this.editingRow) {
      this.cancelEdit();
    }

    console.log('Starting edit mode'); // Debug
    this.editingRow = row;
    this.originalData = this.extractRowData(row);
    console.log('Original data:', this.originalData); // Debug

    if (!this.originalData) {
      console.error('❌ No se pudo extraer los datos de la fila');
      return;
    }

    this.convertToEditMode(row);
  }

  extractRowData(row) {
    if (!row) {
      console.error('❌ extractRowData: row es null');
      return null;
    }

    const cells = row.querySelectorAll('td');
    console.log('Cells found:', cells.length); // Debug

    if (cells.length < 8) {
      console.error('❌ extractRowData: No hay suficientes celdas (td)');
      return null;
    }

    return {
      id: row.dataset.scrapId,
      ref_number: cells[0].textContent.trim(),
      scrap_type: cells[1].textContent.trim(),
      thickness: cells[2].textContent.trim(),
      color: cells[3].textContent.trim(),
      width: parseFloat(cells[4].textContent.trim()),
      height: parseFloat(cells[5].textContent.trim()),
      input_work: cells[6].textContent.trim()
    };
  }

  convertToEditMode(row) {
    const cells = row.querySelectorAll('td');

    // Referencia
    this.createTextInputInCell(cells[0], 'ref_number', this.originalData.ref_number);

    // Tipo de retazo
    this.createScrapTypeSelectInCell(cells[1], this.originalData.scrap_type);

    // Grosor
    this.createThicknessSelectInCell(cells[2], this.originalData.thickness, this.originalData.scrap_type);

    // Color
    this.createColorSelectInCell(cells[3], this.originalData.color, this.originalData.scrap_type, this.originalData.thickness);

    // Ancho
    this.createNumberInputInCell(cells[4], 'width', this.originalData.width);

    // Alto
    this.createNumberInputInCell(cells[5], 'height', this.originalData.height);

    // Obra
    this.createTextInputInCell(cells[6], 'input_work', this.originalData.output_work);

    // Acciones
    cells[8].innerHTML = this.createActionButtons();

    this.setupDependentSelects(row);
    this.bindActionButtons(row);
  }

  createTextInputInCell(cell, name, value) {
    console.log('Creating text input in cell:', { name, value }); // Debug
    cell.innerHTML = ''; // Clear cell content
    const input = document.createElement('input');
    input.type = 'text';
    input.name = name;
    input.value = value || '';
    input.className = 'w-full border rounded px-2 py-1 text-center';
    cell.appendChild(input);
  }

  createScrapTypeSelectInCell(cell, currentValue) {
    console.log('Creating scrap type select in cell:', currentValue); // Debug
    cell.innerHTML = ''; // Clear cell content
    const select = document.createElement('select');
    select.className = 'w-full border rounded px-2 py-1 scrap-type-select';
    select.name = 'scrap_type';

    // Usar las opciones de GLASS_OPTIONS
    const glassTypes = Object.keys(this.glassOptions);

    glassTypes.forEach(type => {
      const optionElement = document.createElement('option');
      optionElement.value = type;
      optionElement.textContent = type;
      if (type === currentValue) {
        optionElement.selected = true;
      }
      select.appendChild(optionElement);
    });

    cell.appendChild(select);
  }

  createThicknessSelectInCell(cell, currentValue, currentType) {
    console.log('Creating thickness select in cell:', { currentValue, currentType }); // Debug
    cell.innerHTML = ''; // Clear cell content
    const select = document.createElement('select');
    select.className = 'w-full border rounded px-2 py-1 scrap-thickness-select';
    select.name = 'thickness';

    // Obtener grosores disponibles para el tipo actual
    const availableThicknesses = Object.keys(this.glassOptions[currentType] || {});
    console.log('Available thicknesses for', currentType, ':', availableThicknesses); // Debug

    availableThicknesses.forEach(thickness => {
      const optionElement = document.createElement('option');
      optionElement.value = thickness;
      optionElement.textContent = thickness;
      if (thickness === currentValue) {
        optionElement.selected = true;
      }
      select.appendChild(optionElement);
    });

    cell.appendChild(select);
  }

  createColorSelectInCell(cell, currentValue, currentType, currentThickness) {
    console.log('Creating color select in cell:', { currentValue, currentType, currentThickness }); // Debug
    cell.innerHTML = ''; // Clear cell content
    const select = document.createElement('select');
    select.className = 'w-full border rounded px-2 py-1 scrap-color-select';
    select.name = 'color';

    // Obtener colores disponibles para el tipo y grosor actual
    const availableColors = this.glassOptions[currentType]?.[currentThickness] || [];
    console.log('Available colors for', currentType, currentThickness, ':', availableColors); // Debug

    availableColors.forEach(color => {
      const optionElement = document.createElement('option');
      optionElement.value = color;
      optionElement.textContent = color;
      if (color === currentValue) {
        optionElement.selected = true;
      }
      select.appendChild(optionElement);
    });

    cell.appendChild(select);
  }

  createNumberInputInCell(cell, name, value, min = 0.01) {
    console.log('Creating number input in cell:', { name, value }); // Debug
    cell.innerHTML = ''; // Clear cell content
    const input = document.createElement('input');
    input.type = 'number';
    input.name = name;
    input.value = value;
    input.min = min;
    input.step = '0.01';
    input.className = 'w-full border rounded px-2 py-1 text-center';
    cell.appendChild(input);
  }

  setupDependentSelects(row) {
    const typeSelect = row.querySelector('.scrap-type-select');
    const thicknessSelect = row.querySelector('.scrap-thickness-select');
    const colorSelect = row.querySelector('.scrap-color-select');

    if (typeSelect) {
      typeSelect.addEventListener('change', () => {
        const selectedType = typeSelect.value;
        console.log('Type changed to:', selectedType); // Debug

        // Actualizar grosor
        this.updateThicknessOptions(thicknessSelect, selectedType);

        // Actualizar color
        const currentThickness = thicknessSelect.value;
        this.updateColorOptions(colorSelect, selectedType, currentThickness);
      });
    }

    if (thicknessSelect) {
      thicknessSelect.addEventListener('change', () => {
        const selectedType = typeSelect.value;
        const selectedThickness = thicknessSelect.value;
        console.log('Thickness changed to:', selectedThickness); // Debug

        // Actualizar color
        this.updateColorOptions(colorSelect, selectedType, selectedThickness);
      });
    }
  }

  updateThicknessOptions(thicknessSelect, glassType) {
    if (!thicknessSelect) return;

    const availableThicknesses = Object.keys(this.glassOptions[glassType] || {});
    console.log('Updating thickness options for', glassType, ':', availableThicknesses); // Debug

    // Limpiar opciones existentes
    thicknessSelect.innerHTML = '';

    // Agregar nuevas opciones
    availableThicknesses.forEach(thickness => {
      const optionElement = document.createElement('option');
      optionElement.value = thickness;
      optionElement.textContent = thickness;
      thicknessSelect.appendChild(optionElement);
    });
  }

  updateColorOptions(colorSelect, glassType, thickness) {
    if (!colorSelect) return;

    const availableColors = this.glassOptions[glassType]?.[thickness] || [];
    console.log('Updating color options for', glassType, thickness, ':', availableColors); // Debug

    // Limpiar opciones existentes
    colorSelect.innerHTML = '';

    // Agregar nuevas opciones
    availableColors.forEach(color => {
      const optionElement = document.createElement('option');
      optionElement.value = color;
      optionElement.textContent = color;
      colorSelect.appendChild(optionElement);
    });
  }

  createActionButtons() {
    return `
      <div class="flex gap-2 justify-center">
        <button type="button" class="save-scrap-btn w-8 h-8 rounded-full bg-green-100 hover:bg-green-200 text-green-600 transition-colors duration-150 inline-flex items-center justify-center" title="Guardar">
          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"/>
          </svg>
        </button>
        <button type="button" class="cancel-scrap-btn w-8 h-8 rounded-full bg-gray-100 hover:bg-gray-200 text-gray-600 transition-colors duration-150 inline-flex items-center justify-center" title="Cancelar">
          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/>
          </svg>
        </button>
      </div>
    `;
  }

  bindActionButtons(row) {
    const saveBtn = row.querySelector('.save-scrap-btn');
    const cancelBtn = row.querySelector('.cancel-scrap-btn');

    if (saveBtn) {
      saveBtn.addEventListener('click', () => this.saveEdit(row));
    }

    if (cancelBtn) {
      cancelBtn.addEventListener('click', () => this.cancelEdit());
    }
  }

  saveEdit(row) {
    console.log('Saving scrap edit'); // Debug

    const formData = new FormData();
    formData.append('scrap[id]', this.originalData.id);

    // Recopilar datos de los campos editables
    const inputs = row.querySelectorAll('input, select');
    inputs.forEach(input => {
      if (input.name && input.value !== '') {
        console.log('Adding field:', input.name, '=', input.value); // Debug
        formData.append(`scrap[${input.name}]`, input.value);
      }
    });

    // Log de todos los datos que se van a enviar
    console.log('FormData contents:');
    for (let [key, value] of formData.entries()) {
      console.log(key, ':', value);
    }

    // Enviar datos al servidor
    fetch(`/scraps/${this.originalData.id}`, {
      method: 'PATCH',
      body: formData,
      headers: {
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').getAttribute('content'),
        'Accept': 'application/json'
      }
    })
    .then(response => {
      console.log('Response status:', response.status); // Debug
      if (response.ok) {
        return response.json();
      } else {
        return response.text().then(text => {
          console.error('Server response:', text); // Debug
          throw new Error(`HTTP ${response.status}: ${text}`);
        });
      }
    })
    .then(data => {
      console.log('Scrap saved successfully:', data);
      this.showMessage('Retazo actualizado correctamente', 'success');
      // Recargar la página para mostrar los cambios
      window.location.reload();
    })
    .catch(error => {
      console.error('Error saving scrap:', error);
      this.showMessage(`Error al actualizar el retazo: ${error.message}`, 'error');
    });
  }

  cancelEdit() {
    if (this.editingRow) {
      console.log('Cancelling edit'); // Debug
      // Recargar la página para restaurar el estado original
      window.location.reload();
    }
  }

  showMessage(message, type) {
    // Crear elemento de mensaje temporal
    const messageDiv = document.createElement('div');
    messageDiv.className = `fixed top-4 right-4 px-4 py-2 rounded-md text-white z-50 ${
      type === 'success' ? 'bg-green-500' : 'bg-red-500'
    }`;
    messageDiv.textContent = message;

    document.body.appendChild(messageDiv);

    // Remover después de 3 segundos
    setTimeout(() => {
      if (messageDiv.parentNode) {
        messageDiv.parentNode.removeChild(messageDiv);
      }
    }, 3000);
  }
}

let scrapEditor = null;

document.addEventListener('turbo:load', () => {
  console.log('Turbo loaded, initializing scrap editor'); // Debug
  if (!scrapEditor) {
    scrapEditor = new ScrapInlineEditor();
    window.scrapEditor = scrapEditor; // Exponer globalmente para debug
  }
});

if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', () => {
    console.log('DOM loaded, initializing scrap editor'); // Debug
    if (!scrapEditor) {
      scrapEditor = new ScrapInlineEditor();
      window.scrapEditor = scrapEditor; // Exponer globalmente para debug
    }
  });
} else {
  console.log('DOM already loaded, initializing scrap editor'); // Debug
  if (!scrapEditor) {
    scrapEditor = new ScrapInlineEditor();
    window.scrapEditor = scrapEditor; // Exponer globalmente para debug
  }
}
