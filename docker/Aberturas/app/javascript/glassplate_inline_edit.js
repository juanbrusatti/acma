// glassplate_inline_edit.js
// Módulo para edición inline de planchas de vidrio
// Versión simplificada sin imports externos

class GlassplateInlineEditor {
  constructor() {
    this.editingRow = null;
    this.originalData = null;
    this.glassOptions = {
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
    this.init();
  }

  init() {
    this.setupEventListeners();
  }

  setupEventListeners() {
    document.addEventListener('turbo:load', () => {
      this.bindEditButtons();
    });
    
    // También bindear inmediatamente si ya está cargado
    this.bindEditButtons();
  }

  bindEditButtons() {
    document.querySelectorAll('.edit-glassplate-btn').forEach(btn => {
      // Remover listeners existentes para evitar duplicados
      btn.removeEventListener('click', this.handleEditClick);
      btn.addEventListener('click', (e) => this.handleEditClick(e));
    });
  }

  handleEditClick(e) {
    e.preventDefault();
    console.log('Edit button clicked'); // Debug
    const row = e.target.closest('tr');
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
    this.convertToEditMode(row);
  }

  extractRowData(row) {
    const cells = row.querySelectorAll('td');
    return {
      id: row.dataset.glassplateId,
      glass_type: cells[0].textContent.trim(),
      thickness: cells[1].textContent.trim(),
      color: cells[2].textContent.trim(),
      width: parseFloat(cells[3].textContent.trim()),
      height: parseFloat(cells[4].textContent.trim()),
      quantity: parseInt(cells[5].textContent.trim())
    };
  }

  convertToEditMode(row) {
    const cells = row.querySelectorAll('td');
    
    // Tipo de vidrio
    this.createTypeSelectInCell(cells[0], this.originalData.glass_type);
    
    // Grosor
    this.createThicknessSelectInCell(cells[1], this.originalData.thickness, this.originalData.glass_type);
    
    // Color
    this.createColorSelectInCell(cells[2], this.originalData.color, this.originalData.glass_type, this.originalData.thickness);
    
    // Ancho
    this.createNumberInputInCell(cells[3], 'width', this.originalData.width);
    
    // Alto
    this.createNumberInputInCell(cells[4], 'height', this.originalData.height);
    
    // Cantidad
    this.createNumberInputInCell(cells[5], 'quantity', this.originalData.quantity, 0);
    
    // Acciones
    cells[6].innerHTML = this.createActionButtons();
    
    // Configurar selects dependientes
    this.setupDependentSelects(row);
  }

  createTypeSelectInCell(cell, currentValue) {
    console.log('Creating type select in cell:', currentValue); // Debug
    cell.innerHTML = '';
    
    const select = document.createElement('select');
    select.className = 'w-full border rounded px-2 py-1 glassplate-type-select';
    select.name = 'glass_type';
    
    const defaultOption = document.createElement('option');
    defaultOption.value = '';
    defaultOption.textContent = 'Seleccionar';
    select.appendChild(defaultOption);
    
    Object.keys(this.glassOptions).forEach(type => {
      const option = document.createElement('option');
      option.value = type;
      option.textContent = type;
      option.selected = type === currentValue;
      select.appendChild(option);
    });
    
    cell.appendChild(select);
  }

  createThicknessSelectInCell(cell, currentValue, currentType) {
    console.log('Creating thickness select in cell:', { currentValue, currentType }); // Debug
    cell.innerHTML = '';
    
    const select = document.createElement('select');
    select.className = 'w-full border rounded px-2 py-1 glassplate-thickness-select';
    select.name = 'thickness';
    
    const defaultOption = document.createElement('option');
    defaultOption.value = '';
    defaultOption.textContent = 'Seleccionar';
    select.appendChild(defaultOption);
    
    // Llenar con opciones disponibles para el tipo actual
    if (this.glassOptions[currentType]) {
      const grosores = Object.keys(this.glassOptions[currentType]);
      console.log('Available thicknesses for', currentType, ':', grosores); // Debug
      grosores.forEach(grosor => {
        const opt = document.createElement('option');
        opt.value = grosor;
        opt.textContent = grosor;
        opt.selected = grosor === currentValue;
        select.appendChild(opt);
      });
    } else {
      console.log('No glass options found for type:', currentType); // Debug
    }
    
    cell.appendChild(select);
  }

  createColorSelectInCell(cell, currentValue, currentType, currentThickness) {
    console.log('Creating color select in cell:', { currentValue, currentType, currentThickness }); // Debug
    cell.innerHTML = '';
    
    const select = document.createElement('select');
    select.className = 'w-full border rounded px-2 py-1 glassplate-color-select';
    select.name = 'color';
    
    const defaultOption = document.createElement('option');
    defaultOption.value = '';
    defaultOption.textContent = 'Seleccionar';
    select.appendChild(defaultOption);
    
    // Llenar con opciones disponibles para el tipo y grosor actuales
    if (this.glassOptions[currentType] && this.glassOptions[currentType][currentThickness]) {
      const colores = this.glassOptions[currentType][currentThickness];
      console.log('Available colors for', currentType, currentThickness, ':', colores); // Debug
      colores.forEach(color => {
        const opt = document.createElement('option');
        opt.value = color;
        opt.textContent = color;
        opt.selected = color === currentValue;
        select.appendChild(opt);
      });
    } else {
      console.log('No color options found for:', currentType, currentThickness); // Debug
    }
    
    cell.appendChild(select);
  }

  createNumberInputInCell(cell, name, value, min = 0.01) {
    console.log('Creating number input in cell:', { name, value }); // Debug
    cell.innerHTML = '';
    
    const input = document.createElement('input');
    input.type = 'number';
    input.name = name;
    input.value = value;
    input.min = min;
    input.step = name === 'quantity' ? '1' : '0.01';
    input.className = 'w-full border rounded px-2 py-1 text-center';
    
    cell.appendChild(input);
  }

  createNumberInput(name, value, min = 0.01) {
    const input = document.createElement('input');
    input.type = 'number';
    input.name = name;
    input.value = value;
    input.min = min;
    input.step = name === 'quantity' ? '1' : '0.01';
    input.className = 'w-full border rounded px-2 py-1 text-center';
    return input.outerHTML;
  }

  createActionButtons() {
    return `
      <div class="flex gap-2 justify-center">
        <button type="button" class="save-glassplate-btn bg-green-500 hover:bg-green-600 text-white px-3 py-1 rounded text-sm">
          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"/>
          </svg>
        </button>
        <button type="button" class="cancel-glassplate-btn bg-gray-500 hover:bg-gray-600 text-white px-3 py-1 rounded text-sm">
          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/>
          </svg>
        </button>
      </div>
    `;
  }

  setupDependentSelects(row) {
    const typeSelect = row.querySelector('.glassplate-type-select');
    const thicknessSelect = row.querySelector('.glassplate-thickness-select');
    const colorSelect = row.querySelector('.glassplate-color-select');
    
    if (!typeSelect || !thicknessSelect || !colorSelect) return;
    
    // Función para actualizar grosores cuando cambia el tipo
    const updateThicknessOptions = () => {
      const tipo = typeSelect.value;
      const currentThickness = thicknessSelect.value;
      const currentColor = colorSelect.value;
      
      thicknessSelect.innerHTML = '<option value="">Seleccionar</option>';
      colorSelect.innerHTML = '<option value="">Seleccionar</option>';
      
      if (this.glassOptions[tipo]) {
        const grosores = Object.keys(this.glassOptions[tipo]);
        grosores.forEach(grosor => {
          const opt = document.createElement('option');
          opt.value = grosor;
          opt.textContent = grosor;
          // Mantener el grosor actual si está disponible en el nuevo tipo
          opt.selected = grosor === currentThickness;
          thicknessSelect.appendChild(opt);
        });
        
        // Si el grosor actual no está disponible en el nuevo tipo, seleccionar el primero
        if (!grosores.includes(currentThickness) && grosores.length > 0) {
          thicknessSelect.value = grosores[0];
        }
        
        // Actualizar colores después de cambiar grosor
        updateColorOptions();
      }
    };
    
    // Función para actualizar colores cuando cambia el grosor
    const updateColorOptions = () => {
      const tipo = typeSelect.value;
      const grosor = thicknessSelect.value;
      const currentColor = colorSelect.value;
      
      colorSelect.innerHTML = '<option value="">Seleccionar</option>';
      
      if (this.glassOptions[tipo] && this.glassOptions[tipo][grosor]) {
        const colores = this.glassOptions[tipo][grosor];
        colores.forEach(color => {
          const opt = document.createElement('option');
          opt.value = color;
          opt.textContent = color;
          // Mantener el color actual si está disponible para el nuevo grosor
          opt.selected = color === currentColor;
          colorSelect.appendChild(opt);
        });
        
        // Si el color actual no está disponible para el nuevo grosor, seleccionar el primero
        if (!colores.includes(currentColor) && colores.length > 0) {
          colorSelect.value = colores[0];
        }
      }
    };
    
    // Event listeners
    typeSelect.addEventListener('change', updateThicknessOptions);
    thicknessSelect.addEventListener('change', updateColorOptions);
    
    // Bind save and cancel buttons
    this.bindActionButtons(row);
  }

  bindActionButtons(row) {
    const saveBtn = row.querySelector('.save-glassplate-btn');
    const cancelBtn = row.querySelector('.cancel-glassplate-btn');
    
    if (saveBtn) {
      saveBtn.addEventListener('click', () => this.saveEdit(row));
    }
    if (cancelBtn) {
      cancelBtn.addEventListener('click', () => this.cancelEdit());
    }
  }

  async saveEdit(row) {
    console.log('Saving edit'); // Debug
    const formData = this.extractFormData(row);
    
    if (!this.validateFormData(formData)) {
      return;
    }
    
    try {
      const response = await this.updateGlassplate(formData);
      
      if (response.success) {
        this.convertToViewMode(row, formData);
        this.showSuccessMessage('Plancha actualizada exitosamente');
        this.editingRow = null;
      } else {
        this.showErrorMessage('Error al actualizar la plancha');
      }
    } catch (error) {
      console.error('Error updating glassplate:', error);
      this.showErrorMessage('Error al actualizar la plancha');
    }
  }

  extractFormData(row) {
    const formData = {
      id: this.originalData.id,
      glass_type: row.querySelector('.glassplate-type-select').value,
      thickness: row.querySelector('.glassplate-thickness-select').value,
      color: row.querySelector('.glassplate-color-select').value,
      width: parseFloat(row.querySelector('input[name="width"]').value),
      height: parseFloat(row.querySelector('input[name="height"]').value),
      quantity: parseInt(row.querySelector('input[name="quantity"]').value)
    };
    
    return formData;
  }

  validateFormData(data) {
    const errors = [];
    
    if (!data.glass_type) errors.push('Tipo de vidrio es requerido');
    if (!data.thickness) errors.push('Grosor es requerido');
    if (!data.color) errors.push('Color es requerido');
    if (!data.width || data.width <= 0) errors.push('Ancho debe ser mayor a 0');
    if (!data.height || data.height <= 0) errors.push('Alto debe ser mayor a 0');
    if (data.quantity < 0) errors.push('Cantidad no puede ser negativa');
    
    if (errors.length > 0) {
      this.showErrorMessage(errors.join(', '));
      return false;
    }
    
    return true;
  }

  async updateGlassplate(data) {
    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.getAttribute('content');
    
    const response = await fetch(`/glassplates/${data.id}`, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': csrfToken,
        'Accept': 'application/json'
      },
      body: JSON.stringify({
        glassplate: data
      })
    });
    
    return await response.json();
  }

  convertToViewMode(row, data) {
    const cells = row.querySelectorAll('td');
    
    cells[0].textContent = data.glass_type;
    cells[1].textContent = data.thickness;
    cells[2].textContent = data.color;
    cells[3].textContent = data.width;
    cells[4].textContent = data.height;
    cells[5].textContent = data.quantity;
    cells[6].innerHTML = this.createViewModeActions();
    
    // Rebind edit button
    this.bindEditButtons();
  }

  createViewModeActions() {
    return `
      <div class="flex gap-2 justify-center">
        <button type="button" class="edit-glassplate-btn w-8 h-8 rounded-full bg-blue-100 hover:bg-blue-200 text-blue-600 transition-colors duration-150 inline-flex items-center justify-center" title="Editar">
          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002 2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"/>
          </svg>
        </button>
        <a href="/glassplates/${this.originalData.id}" data-turbo-method="delete" data-turbo-confirm="¿Estás seguro de que quieres eliminar esta plancha?" class="w-8 h-8 rounded-full bg-red-100 hover:bg-red-200 text-red-600 transition-colors duration-150 inline-flex items-center justify-center" title="Eliminar">
          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"/>
          </svg>
        </a>
      </div>
    `;
  }

  cancelEdit() {
    if (this.editingRow && this.originalData) {
      this.convertToViewMode(this.editingRow, this.originalData);
      this.editingRow = null;
      this.originalData = null;
    }
  }

  showSuccessMessage(message) {
    this.showMessage(message, 'success');
  }

  showErrorMessage(message) {
    this.showMessage(message, 'error');
  }

  showMessage(message, type) {
    const messageDiv = document.createElement('div');
    messageDiv.className = `fixed top-4 right-4 px-4 py-2 rounded shadow-lg z-50 ${
      type === 'success' 
        ? 'bg-green-100 border border-green-400 text-green-700' 
        : 'bg-red-100 border border-red-400 text-red-700'
    }`;
    messageDiv.textContent = message;
    
    document.body.appendChild(messageDiv);
    
    setTimeout(() => {
      if (messageDiv.parentNode) {
        messageDiv.parentNode.removeChild(messageDiv);
      }
    }, 3000);
  }
}

// Inicializar el editor cuando se carga la página
let glassplateEditor = null;

document.addEventListener('turbo:load', () => {
  console.log('Turbo loaded, initializing glassplate editor'); // Debug
  if (!glassplateEditor) {
    glassplateEditor = new GlassplateInlineEditor();
    window.glassplateEditor = glassplateEditor; // Exponer globalmente para debug
  }
});

// También inicializar inmediatamente si ya está cargado
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', () => {
    console.log('DOM loaded, initializing glassplate editor'); // Debug
    if (!glassplateEditor) {
      glassplateEditor = new GlassplateInlineEditor();
      window.glassplateEditor = glassplateEditor; // Exponer globalmente para debug
    }
  });
} else {
  console.log('DOM already loaded, initializing glassplate editor'); // Debug
  if (!glassplateEditor) {
    glassplateEditor = new GlassplateInlineEditor();
    window.glassplateEditor = glassplateEditor; // Exponer globalmente para debug
  }
}