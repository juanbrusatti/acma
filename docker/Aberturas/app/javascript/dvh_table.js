// DVH (Double Glazing) Table Module
// Manages dynamic table creation and manipulation for double-glazed window entries in projects
// DVH stands for "Doble Vidriado Hermético" (Hermetic Double Glazing)
import { updateDvhGlassSelects } from "dvh_selects";
import { getDvhTotalGlassPrice, calculateInnertubeTotal, getGlassPriceM2, requireFields, validateQuantity } from "utils";

// Función para formatear números en formato argentino
function formatArgentineCurrency(amount, unit = "$") {
  if (amount === null || amount === undefined || isNaN(amount)) {
    return "N/A";
  }
  
  // Convertir a número y redondear a 2 decimales
  const num = Math.round(parseFloat(amount) * 100) / 100;
  
  // Convertir a string y separar parte entera y decimal
  const parts = num.toString().split('.');
  const integerPart = parts[0];
  const decimalPart = parts[1] || '00';
  
  // Agregar separadores de miles (puntos)
  const formattedInteger = integerPart.replace(/\B(?=(\d{3})+(?!\d))/g, '.');
  
  // Asegurar que la parte decimal tenga 2 dígitos
  const formattedDecimal = decimalPart.padEnd(2, '0').substring(0, 2);
  
  return `${unit}${formattedInteger},${formattedDecimal}`;
}

// Global variables to track table state and unique IDs
let dvhIdCounter = 1;
let dvhTable = null;
let dvhTbody = null;

// Pure builder for DVH table row and corresponding hidden inputs
function buildDvhRow(values, price, index) {
  const tempId = `new_${Date.now()}_${index}`;
  
  const tr = document.createElement("tr");
  tr.className = "divide-x divide-gray-200";
  tr.innerHTML = `
    <td class='px-4 py-2 text-center'>${values.typology || ''}</td>
    <td class='px-4 py-2 text-center'>${values.innertube || ''}</td>
    <td class='px-4 py-2 text-center'>${values.height || ''}</td>
    <td class='px-4 py-2 text-center'>${values.width || ''}</td>
    <td class='px-4 py-2 text-center'>${values.glasscutting1_type || ''} / ${values.glasscutting1_thickness || ''} / ${values.glasscutting1_color || ''}</td>
    <td class='px-4 py-2 text-center'>${values.glasscutting2_type || ''} / ${values.glasscutting2_thickness || ''} / ${values.glasscutting2_color || ''}</td>
    <td class='px-4 py-2 text-center'>${values.type_opening || ''}</td>
    <td class='px-4 py-2 text-center'>${formatArgentineCurrency(price, '$') || ''}</td>
    <td class="px-4 py-2 text-center">
      <div class="flex space-x-1 justify-center">
        <button type="button" class="edit-dvh bg-blue-500 text-white px-2 py-1 rounded text-xs hover:bg-blue-600" data-temp-id="${tempId}">Editar</button>
        <button type="button" class="delete-dvh bg-red-500 text-white px-2 py-1 rounded text-xs hover:bg-red-600">Eliminar</button>
      </div>
    </td>
  `;

  // Hidden form inputs for Rails submission
  const hiddenDiv = document.createElement("div");
  hiddenDiv.style.display = "none";
  hiddenDiv.className = "dvh-hidden-row";
  hiddenDiv.innerHTML = `
    <input type="hidden" name="project[dvhs_attributes][${tempId}][typology]" value="${values.typology || ''}">
    <input type="hidden" name="project[dvhs_attributes][${tempId}][innertube]" value="${values.innertube || ''}">
    <input type="hidden" name="project[dvhs_attributes][${tempId}][height]" value="${values.height || ''}">
    <input type="hidden" name="project[dvhs_attributes][${tempId}][width]" value="${values.width || ''}">
    <input type="hidden" name="project[dvhs_attributes][${tempId}][glasscutting1_type]" value="${values.glasscutting1_type || ''}">
    <input type="hidden" name="project[dvhs_attributes][${tempId}][glasscutting1_thickness]" value="${values.glasscutting1_thickness || ''}">
    <input type="hidden" name="project[dvhs_attributes][${tempId}][glasscutting1_color]" value="${values.glasscutting1_color || ''}">
    <input type="hidden" name="project[dvhs_attributes][${tempId}][glasscutting2_type]" value="${values.glasscutting2_type || ''}">
    <input type="hidden" name="project[dvhs_attributes][${tempId}][glasscutting2_thickness]" value="${values.glasscutting2_thickness || ''}">
    <input type="hidden" name="project[dvhs_attributes][${tempId}][glasscutting2_color]" value="${values.glasscutting2_color || ''}">
    <input type="hidden" name="project[dvhs_attributes][${tempId}][type_opening]" value="${values.type_opening || ''}">
    <input type="hidden" name="project[dvhs_attributes][${tempId}][price]" value="${price.toFixed(2)}">
    <input type="hidden" name="project[dvhs_attributes][${tempId}][_destroy]" value="0">
  `;

  tr.setAttribute('data-temp-id', tempId);

  return { tr, hiddenDiv, tempId };
}

// Ensures the DVH table exists in the DOM
// Creates the table structure if it doesn't exist, or references existing one
export function ensureDvhTable() {
  const container = document.getElementById('dvhs-table-container');
  const existingTable = container.querySelector('table');
  
  // If table already exists, just reference it
  if (existingTable) {
    dvhTable = existingTable;
    dvhTbody = existingTable.querySelector('tbody');
    return;
  }
  
  // Create new table if it doesn't exist
  if (!dvhTable) {
    dvhTable = document.createElement('table');
    dvhTable.className = 'min-w-full text-xs text-gray-700 border';
    
    // Create table header with column definitions for DVH specifications
    dvhTable.innerHTML = `
      <thead>
        <tr class='bg-gray-50 text-gray-500'>
          <th class='px-4 py-2 text-center'>TIPOLOGÍA</th>
          <th class='px-6 py-2 text-center'>CÁMARA</th>
          <th class='px-4 py-2 text-center'>ALTO</th>
          <th class='px-4 py-2 text-center'>ANCHO</th>
          <th class='px-4 py-2 text-center'>CRISTAL 1</th>
          <th class='px-4 py-2 text-center'>CRISTAL 2</th>
          <th class='px-4 py-2 text-center'>ABERTURA</th>
          <th class='px-4 py-2 text-center'>PRECIO</th>
          <th class='px-4 py-2 text-center'>ACCION</th>
        </tr>
      </thead>
    `;
    
    // Create and append table body
    dvhTbody = document.createElement('tbody');
    dvhTbody.id = 'dvhs-table-body';
    dvhTable.appendChild(dvhTbody);
    container.appendChild(dvhTable);
  }
}

// Removes the table from DOM if it's empty (no rows)
// Helps keep the interface clean when no DVH entries exist
export function removeDvhTableIfEmpty() {
  if (dvhTbody && dvhTbody.children.length === 0) {
    if (dvhTable && dvhTable.parentNode) {
      // Remove table includes <thead>
      dvhTable.parentNode.removeChild(dvhTable);
    }
    dvhTable = null;
    dvhTbody = null;
  }
}

// Main event handler for DVH related actions
// Handles confirm, delete, and cancel operations for double-glazed windows
export function handleDvhEvents(e) {
  // EDIT: Handle edit buttons for existing DVHs
  if (e.target.closest('.edit-dvh')) {
    const button = e.target.closest('.edit-dvh');
    const id = button.getAttribute('data-id');
    const row = button.closest('tr');
    const tempId = button.getAttribute('data-temp-id') || (row && row.getAttribute('data-temp-id'));
    
    if (id || tempId) {
      // Read current values from row
      const typology = row.querySelector('td:nth-child(1)').textContent.trim();
      const innertube = row.querySelector('td:nth-child(2)').textContent.trim();
      const width = row.querySelector('td:nth-child(3)').textContent.trim();
      const height = row.querySelector('td:nth-child(4)').textContent.trim();
      const type_opening = row.querySelector('td:nth-child(7)').textContent.trim();

      const glass1Text = row.querySelector('td:nth-child(5)').textContent.trim();
      const glass2Text = row.querySelector('td:nth-child(6)').textContent.trim();
      function parseSpecs(t) {
        if (!t || t === 'N/A') return { type: '', thickness: '', color: '' };
        if (t.includes('/')) {
          const a = t.split('/').map(s => s.trim());
          return { type: a[0] || '', thickness: a[1] || '', color: a[2] || '' };
        }
        const a = t.split(/\s+/).filter(Boolean);
        return { type: a[0] || '', thickness: a[1] || '', color: a[2] || '' };
      }
      const g1 = parseSpecs(glass1Text);
      const g2 = parseSpecs(glass2Text);
      const glass1Type = g1.type;
      const glass1Thickness = g1.thickness;
      const glass1Color = g1.color;
      const glass2Type = g2.type;
      const glass2Thickness = g2.thickness;
      const glass2Color = g2.color;

      // Hide original row
      row.style.display = 'none';

      // Create full-width table row to host the edit form
      const editRow = document.createElement('tr');
      const td = document.createElement('td');
      td.colSpan = row.children.length; // span all columns
      editRow.appendChild(td);

      // Clone DVH template
      const template = document.getElementById('dvh-template');
      const editContainer = template.content.cloneNode(true).querySelector('.dvh-fields');
      // Mark as edit form for existing save/cancel handlers
      editContainer.classList.add('dvh-edit-form');

      // Convert template buttons into Save/Cancel for edit
      const confirmBtn = editContainer.querySelector('.confirm-dvh');
      const cancelBtn = editContainer.querySelector('.cancel-dvh');
      if (confirmBtn) {
        confirmBtn.classList.remove('confirm-dvh');
        confirmBtn.classList.add('save-dvh-edit');
        if (id) confirmBtn.setAttribute('data-id', id);
        if (tempId) confirmBtn.setAttribute('data-temp-id', tempId);
        confirmBtn.textContent = 'Guardar';
      }
      if (cancelBtn) {
        cancelBtn.classList.remove('cancel-dvh');
        cancelBtn.classList.add('cancel-dvh-edit');
        cancelBtn.textContent = 'Cancelar';
      }

      // Ocultar el campo cantidad en modo edición
      const quantityField = editContainer.querySelector('.quantity-field[data-only-create]');
      if (quantityField) {
        quantityField.style.display = 'none';
      }

      // Append container into td and insert before the row
      td.appendChild(editContainer);
      row.parentNode.insertBefore(editRow, row);

      // Prefill values
      // Typology: template uses number + hidden Vx
      const typologyInput = editContainer.querySelector('.typology-number-input');
      const typologyHidden = editContainer.querySelector('.typology-hidden-field');
      const typologyNumber = typology.replace(/^V/i, '');
      if (typologyInput) typologyInput.value = typologyNumber;
      if (typologyHidden) typologyHidden.value = typology;

      const innertubeSelect = editContainer.querySelector('select[name="project[dvhs_attributes][][innertube]"]');
      const widthInput = editContainer.querySelector('input[name="project[dvhs_attributes][][width]"]');
      const heightInput = editContainer.querySelector('input[name="project[dvhs_attributes][][height]"]');
      const type_openingSelect = editContainer.querySelector('select[name="project[dvhs_attributes][][type_opening]"]');
      if (innertubeSelect) innertubeSelect.value = innertube;
      if (widthInput) widthInput.value = width;
      if (heightInput) heightInput.value = height;
      if (type_openingSelect) type_openingSelect.value = type_opening;

      // Initialize dependent selects and set values in order for Glass 1
      updateDvhGlassSelects(editContainer, 'glasscutting1');
      const g1Type = editContainer.querySelector('.glasscutting1-type-select');
      const g1Thk = editContainer.querySelector('.glasscutting1-thickness-select');
      const g1Color = editContainer.querySelector('.glasscutting1-color-select');
      if (g1Type) g1Type.value = glass1Type;
      updateDvhGlassSelects(editContainer, 'glasscutting1');
      if (g1Thk) {
        g1Thk.value = glass1Thickness;
        g1Thk.dispatchEvent(new Event('change', { bubbles: true }));
      }
      if (g1Color) {
        if (glass1Color && !Array.from(g1Color.options).some(o => o.value === glass1Color)) {
          const opt = document.createElement('option');
          opt.value = glass1Color;
          opt.textContent = glass1Color;
          g1Color.appendChild(opt);
        }
        g1Color.value = glass1Color;
      }

      // Initialize dependent selects and set values in order for Glass 2
      updateDvhGlassSelects(editContainer, 'glasscutting2');
      const g2Type = editContainer.querySelector('.glasscutting2-type-select');
      const g2Thk = editContainer.querySelector('.glasscutting2-thickness-select');
      const g2Color = editContainer.querySelector('.glasscutting2-color-select');
      if (g2Type) g2Type.value = glass2Type;
      updateDvhGlassSelects(editContainer, 'glasscutting2');
      if (g2Thk) {
        g2Thk.value = glass2Thickness;
        g2Thk.dispatchEvent(new Event('change', { bubbles: true }));
      }
      if (g2Color) {
        if (glass2Color && !Array.from(g2Color.options).some(o => o.value === glass2Color)) {
          const opt = document.createElement('option');
          opt.value = glass2Color;
          opt.textContent = glass2Color;
          g2Color.appendChild(opt);
        }
        g2Color.value = glass2Color;
      }
    }
    return;
  }
  
  // SAVE: Handle save button for DVH edit
  if (e.target.closest('.save-dvh-edit')) {
    const button = e.target.closest('.save-dvh-edit');
    const id = button.getAttribute('data-id');
    const tempId = button.getAttribute('data-temp-id');
    const editContainer = button.closest('.dvh-edit-form');
    const editRow = editContainer.closest('tr');
    const row = editRow.nextElementSibling; // original hidden row

    // Get values from template-based edit form
    const typologyHidden = editContainer.querySelector('.typology-hidden-field');
    const typologyNumberInput = editContainer.querySelector('.typology-number-input');
    const typology = (typologyHidden && typologyHidden.value) || (typologyNumberInput && typologyNumberInput.value ? 'V' + typologyNumberInput.value : '');

    const type_openingSelect = editContainer.querySelector('select[name="project[dvhs_attributes][][type_opening]"]');
    const innertubeSelect = editContainer.querySelector('select[name="project[dvhs_attributes][][innertube]"]');
    const widthInput = editContainer.querySelector('input[name="project[dvhs_attributes][][width]"]');
    const heightInput = editContainer.querySelector('input[name="project[dvhs_attributes][][height]"]');
    const innertube = innertubeSelect ? innertubeSelect.value : '';
    const width = widthInput ? widthInput.value : '';
    const height = heightInput ? heightInput.value : '';
    const type_opening = type_openingSelect ? type_openingSelect.value : '';

    const glass1Type = (editContainer.querySelector('.glasscutting1-type-select') || {}).value || '';
    const glass1Thickness = (editContainer.querySelector('.glasscutting1-thickness-select') || {}).value || '';
    const glass1Color = (editContainer.querySelector('.glasscutting1-color-select') || {}).value || '';

    const glass2Type = (editContainer.querySelector('.glasscutting2-type-select') || {}).value || '';
    const glass2Thickness = (editContainer.querySelector('.glasscutting2-thickness-select') || {}).value || '';
    const glass2Color = (editContainer.querySelector('.glasscutting2-color-select') || {}).value || '';

    // Calculate new price
  const glass1Display = [glass1Type, glass1Thickness, glass1Color].join(' / ');
  const glass2Display = [glass2Type, glass2Thickness, glass2Color].join(' / ');
  const glass1 = { type: glass1Type, thickness: glass1Thickness, color: glass1Color };
  const glass2 = { type: glass2Type, thickness: glass2Thickness, color: glass2Color };
  const price = getDvhTotalGlassPrice(parseFloat(height), parseFloat(width), glass1, glass2, parseFloat(innertube));

  row.querySelector('td:nth-child(1)').textContent = typology;
  row.querySelector('td:nth-child(2)').textContent = innertube;
  row.querySelector('td:nth-child(3)').textContent = width;
  row.querySelector('td:nth-child(4)').textContent = height;
  row.querySelector('td:nth-child(5)').textContent = glass1Display;
  row.querySelector('td:nth-child(6)').textContent = glass2Display;
  row.querySelector('td:nth-child(7)').textContent = type_opening;
  row.querySelector('td:nth-child(8)').textContent = formatArgentineCurrency(price, '$');

    // Show the row again
    row.style.display = '';

    // Remove edit row
    editRow.remove();

    // Update hidden fields (use id or tempId)
    const key = id || tempId;
    const typologyFields = document.querySelectorAll(`input[name="project[dvhs_attributes][][typology]"]`);
    if (typologyFields.length > 0) typologyFields[0].value = typology;
    
    const innertubeFields = document.querySelectorAll(`input[name="project[dvhs_attributes][][innertube]"]`);
    if (innertubeFields.length > 0) innertubeFields[0].value = innertube;
    
    const widthFields = document.querySelectorAll(`input[name="project[dvhs_attributes][][width]"]`);
    if (widthFields.length > 0) widthFields[0].value = width;
    
    const heightFields = document.querySelectorAll(`input[name="project[dvhs_attributes][][height]"]`);
    if (heightFields.length > 0) heightFields[0].value = height;

    const type_openingFields = document.querySelectorAll(`select[name="project[dvhs_attributes][][type_opening]"]`);
    if (type_openingFields.length > 0) type_openingFields[0].value = type_opening;

    const glass1TypeFields = document.querySelectorAll(`input[name="project[dvhs_attributes][][glasscutting1_type]"]`);
    if (glass1TypeFields.length > 0) glass1TypeFields[0].value = glass1Type;
    
    const glass1ThicknessFields = document.querySelectorAll(`input[name="project[dvhs_attributes][][glasscutting1_thickness]"]`);
    if (glass1ThicknessFields.length > 0) glass1ThicknessFields[0].value = glass1Thickness;
    
    const glass1ColorFields = document.querySelectorAll(`input[name="project[dvhs_attributes][][glasscutting1_color]"]`);
    if (glass1ColorFields.length > 0) glass1ColorFields[0].value = glass1Color;
    
    const glass2TypeFields = document.querySelectorAll(`input[name="project[dvhs_attributes][][glasscutting2_type]"]`);
    if (glass2TypeFields.length > 0) glass2TypeFields[0].value = glass2Type;
    
    const glass2ThicknessFields = document.querySelectorAll(`input[name="project[dvhs_attributes][][glasscutting2_thickness]"]`);
    if (glass2ThicknessFields.length > 0) glass2ThicknessFields[0].value = glass2Thickness;
    
    const glass2ColorFields = document.querySelectorAll(`input[name="project[dvhs_attributes][][glasscutting2_color]"]`);
    if (glass2ColorFields.length > 0) glass2ColorFields[0].value = glass2Color;

    const priceFields = document.querySelectorAll(`input[name="project[dvhs_attributes][][price]"]`);
    if (priceFields.length > 0) priceFields[0].value = price.toFixed(2);
    
    // Update project totals
    setTimeout(() => {
      if (typeof window.updateProjectTotals === 'function') {
        window.updateProjectTotals();
      }
    }, 100);
    
    return;
  }
  
  // CANCEL: Handle cancel button for DVH edit
  if (e.target.closest('.cancel-dvh-edit')) {
    const editContainer = e.target.closest('.dvh-edit-form');
    const editRow = editContainer.closest('tr');
    const row = editRow.nextElementSibling;
    
    // Show the row again
    if (row) row.style.display = '';
    
    // Remove edit row
    editRow.remove();
    
    return;
  }
  
  // DELETE: Handle delete buttons for existing DVHs
  if (e.target.closest('.delete-dvh')) {
    const button = e.target.closest('.delete-dvh');
    const id = button.getAttribute('data-id');
    const row = button.closest('tr');
    
    if (id) {
      // Mark for destruction and remove the row from DOM so totals update correctly
      const destroyField = document.getElementById(`dvhs_destroy_${id}`);
      if (destroyField) {
        destroyField.value = '1';
      }
      row.remove();
    } else {
      // For new entries without ID, just remove the row
      row.remove();
      const tempId = row.getAttribute('data-temp-id');
      if (tempId) {
        const hiddenDiv = document.querySelector(`.dvh-hidden-row input[name="project[dvhs_attributes][${tempId}][typology]"]`);
        if (hiddenDiv && hiddenDiv.parentElement && hiddenDiv.parentElement.classList.contains('dvh-hidden-row')) {
          hiddenDiv.parentElement.remove();
        }
      }
    }
    // Si no quedan filas, eliminar la tabla
    const tableBody = document.getElementById('dvhs-table-body');
    if (tableBody) {
      if (tableBody.children.length === 0) {
        const container = document.getElementById('dvhs-table-container');
        if (container) {
          // Remove existing table
          const existingTable = container.querySelector('table');
          if (existingTable) {
            existingTable.remove();
          }
        }
      }
    }
    // Update totals after deletion
    setTimeout(() => {
      if (typeof window.updateProjectTotals === 'function') {
        window.updateProjectTotals();
      }
    }, 100);
    return;
  }
  // CONFIRM: Add new DVH entry to table
  if (e.target.classList.contains("confirm-dvh")) {
    const container = e.target.closest(".dvh-fields");
    
    // Before processing, ensure typology hidden field is updated
    const typologyNumberInput = container.querySelector('.typology-number-input');
    const typologyHidden = container.querySelector('.typology-hidden-field');
    if (typologyNumberInput && typologyHidden && typologyNumberInput.value) {
      typologyHidden.value = "V" + typologyNumberInput.value;
    }
    
    const fields = container.querySelectorAll("input, select");
    
    // Extract values from form inputs
    const values = {};
    fields.forEach(field => {
      // Skip fields without name attribute
      if (!field.name) return;
      // Extract attribute name (e.g., glasscutting1_type)
      const key = field.name.split("[").pop().replace("]", "");
      values[key] = field.value;
    });
    
    // Get quantity value from the quantity input (which doesn't have a name)
    const quantityInput = container.querySelector('.quantity-input');
    values.quantity = quantityInput ? quantityInput.value : '';

    const requiredFields = [
      { key: 'typology', label: 'Tipología' },
      { key: 'innertube', label: 'Cámara' },
      { key: 'height', label: 'Alto' },
      { key: 'width', label: 'Ancho' },
      { key: 'glasscutting1_type', label: 'Tipo del cristal 1' },
      { key: 'glasscutting1_thickness', label: 'Grosor del cristal 1' },
      { key: 'glasscutting1_color', label: 'Color del cristal 1' },
      { key: 'glasscutting2_type', label: 'Tipo del cristal 2' },
      { key: 'glasscutting2_thickness', label: 'Grosor del cristal 2' },
      { key: 'glasscutting2_color', label: 'Color del cristal 2' },
      { key: 'type_opening', label: 'Tipo de apertura' }
    ];
    const missingField = requireFields(values, requiredFields);
    if (missingField) {
      const swalConfig = window.getSwalConfig();
      window.Swal.fire({
        ...swalConfig,
        title: 'Falta rellenar: ' + missingField.label
      });
      return;
    }

    const quantity = parseInt(values.quantity);
    const quantityError = validateQuantity(quantity, 1, 100);
    if (quantityError) {
      const swalConfig = window.getSwalConfig();
      window.Swal.fire({
        ...swalConfig,
        title: quantityError
      });
      return;
    }
    
    // Ensure table exists before adding rows
    ensureDvhTable();
    
    // Parse dimensions for price calculation
    const height = parseFloat(values.height) || 0;
    const width = parseFloat(values.width) || 0;
    
    // Structure glass specifications for both panes
    const glass1 = {
      type: values.glasscutting1_type,
      thickness: values.glasscutting1_thickness,
      color: values.glasscutting1_color
    };
    const glass2 = {
      type: values.glasscutting2_type,
      thickness: values.glasscutting2_thickness,
      color: values.glasscutting2_color
    };
    
    // Calculate total price for both glass panes plus innertube
    const price = getDvhTotalGlassPrice(height, width, glass1, glass2, values.innertube);
    
    // Create multiple rows based on quantity
    for (let i = 0; i < quantity; i++) {
      const { tr, hiddenDiv } = buildDvhRow(values, price, i);
      dvhTbody.appendChild(tr);
      document.getElementById("dvhs-hidden").appendChild(hiddenDiv);
      dvhIdCounter++;
    }
    
    // Update project totals if function exists
    setTimeout(() => {
      if (typeof window.updateProjectTotals === 'function') {
        window.updateProjectTotals();
      }
    }, 100);
    
    // Remove form container
    console.log('Removing DVH form container');
    container.remove();
    console.log('DVH form container removed, checking for remaining forms...');
    const remainingForms = document.querySelectorAll('#dvhs-wrapper .dvh-fields');
    console.log('Remaining DVH forms after removal:', remainingForms.length);
    return;
  }
  
  // DELETE: Remove DVH entry from table
  if (e.target.classList.contains("delete-dvh")) {
    const tr = e.target.closest("tr");
    if (tr) {
      tr.remove();
      removeDvhTableIfEmpty();
      
      // Update project totals after deletion
      setTimeout(() => {
        if (typeof window.updateProjectTotals === 'function') {
          window.updateProjectTotals();
        }
      }, 100);
      
      // Remove corresponding hidden form inputs
      const hiddenRows = document.querySelectorAll("#dvhs-hidden .dvh-hidden-row");
      if (hiddenRows.length > 0) hiddenRows[hiddenRows.length - 1].remove();
      return;
    }
    
    // Handle deletion from form containers
    const container = e.target.closest(".dvh-fields") || e.target.closest(".dvh-view");
    if (container) { container.remove(); return; }
  }
  
  // CANCEL: Remove form without adding entry
  if (e.target.classList.contains("cancel-dvh")) {
    const container = e.target.closest(".dvh-fields");
    console.log('Canceling DVH form, removing container');
    container.remove();
    console.log('Cancel DVH form container removed');
    return;
  }
}

// Resets all module variables to initial state
// Used when starting fresh or clearing data
export function resetDvhTableVars() {
  dvhIdCounter = 1;
  dvhTable = null;
  dvhTbody = null;
}