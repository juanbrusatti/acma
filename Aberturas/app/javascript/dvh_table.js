// DVH (Double Glazing) Table Module
// Manages dynamic table creation and manipulation for double-glazed window entries in projects
// DVH stands for "Doble Vidriado Hermético" (Hermetic Double Glazing)
import { updateDvhGlassSelects } from "dvh_selects";

// Global variables to track table state and unique IDs
let dvhIdCounter = 1;
let dvhTable = null;
let dvhTbody = null;

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
          <th class='px-4 py-2 text-center'>PRECIO</th>
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
      dvhTable.parentNode.removeChild(dvhTable);
    }
    // Reset references to null
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
      if (innertubeSelect) innertubeSelect.value = innertube;
      if (widthInput) widthInput.value = width;
      if (heightInput) heightInput.value = height;

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

    const innertubeSelect = editContainer.querySelector('select[name="project[dvhs_attributes][][innertube]"]');
    const widthInput = editContainer.querySelector('input[name="project[dvhs_attributes][][width]"]');
    const heightInput = editContainer.querySelector('input[name="project[dvhs_attributes][][height]"]');
    const innertube = innertubeSelect ? innertubeSelect.value : '';
    const width = widthInput ? widthInput.value : '';
    const height = heightInput ? heightInput.value : '';

    const glass1Type = (editContainer.querySelector('.glasscutting1-type-select') || {}).value || '';
    const glass1Thickness = (editContainer.querySelector('.glasscutting1-thickness-select') || {}).value || '';
    const glass1Color = (editContainer.querySelector('.glasscutting1-color-select') || {}).value || '';

    const glass2Type = (editContainer.querySelector('.glasscutting2-type-select') || {}).value || '';
    const glass2Thickness = (editContainer.querySelector('.glasscutting2-thickness-select') || {}).value || '';
    const glass2Color = (editContainer.querySelector('.glasscutting2-color-select') || {}).value || '';

    // Calculate new price
    const glass1 = { type: glass1Type, thickness: glass1Thickness, color: glass1Color };
    const glass2 = { type: glass2Type, thickness: glass2Thickness, color: glass2Color };
    const price = getDvhTotalGlassPrice(parseFloat(height), parseFloat(width), glass1, glass2, parseFloat(innertube));

    // Update row content
    row.querySelector('td:nth-child(1)').textContent = typology;
    row.querySelector('td:nth-child(2)').textContent = innertube;
    row.querySelector('td:nth-child(3)').textContent = width;
    row.querySelector('td:nth-child(4)').textContent = height;
    row.querySelector('td:nth-child(5)').textContent = `${glass1Type} ${glass1Thickness} ${glass1Color}`;
    row.querySelector('td:nth-child(6)').textContent = `${glass2Type} ${glass2Thickness} ${glass2Color}`;
    row.querySelector('td:nth-child(7)').textContent = `$${price.toFixed(2)}`;

    // Show the row again
    row.style.display = '';

    // Remove edit row
    editRow.remove();

    // Update hidden fields (use id or tempId)
    const key = id || tempId;
    const typologyFields = document.querySelectorAll(`input[name="project[dvhs_attributes][${key}][typology]"]`);
    if (typologyFields.length > 0) typologyFields[0].value = typology;
    
    const innertubeFields = document.querySelectorAll(`input[name="project[dvhs_attributes][${key}][innertube]"]`);
    if (innertubeFields.length > 0) innertubeFields[0].value = innertube;
    
    const widthFields = document.querySelectorAll(`input[name="project[dvhs_attributes][${key}][width]"]`);
    if (widthFields.length > 0) widthFields[0].value = width;
    
    const heightFields = document.querySelectorAll(`input[name="project[dvhs_attributes][${key}][height]"]`);
    if (heightFields.length > 0) heightFields[0].value = height;
    
    const glass1TypeFields = document.querySelectorAll(`input[name="project[dvhs_attributes][${key}][glasscutting1_type]"]`);
    if (glass1TypeFields.length > 0) glass1TypeFields[0].value = glass1Type;
    
    const glass1ThicknessFields = document.querySelectorAll(`input[name="project[dvhs_attributes][${key}][glasscutting1_thickness]"]`);
    if (glass1ThicknessFields.length > 0) glass1ThicknessFields[0].value = glass1Thickness;
    
    const glass1ColorFields = document.querySelectorAll(`input[name="project[dvhs_attributes][${key}][glasscutting1_color]"]`);
    if (glass1ColorFields.length > 0) glass1ColorFields[0].value = glass1Color;
    
    const glass2TypeFields = document.querySelectorAll(`input[name="project[dvhs_attributes][${key}][glasscutting2_type]"]`);
    if (glass2TypeFields.length > 0) glass2TypeFields[0].value = glass2Type;
    
    const glass2ThicknessFields = document.querySelectorAll(`input[name="project[dvhs_attributes][${key}][glasscutting2_thickness]"]`);
    if (glass2ThicknessFields.length > 0) glass2ThicknessFields[0].value = glass2Thickness;
    
    const glass2ColorFields = document.querySelectorAll(`input[name="project[dvhs_attributes][${key}][glasscutting2_color]"]`);
    if (glass2ColorFields.length > 0) glass2ColorFields[0].value = glass2Color;
    
    const priceFields = document.querySelectorAll(`input[name="project[dvhs_attributes][${key}][price]"]`);
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
      // Mark for destruction instead of removing, in case it's an existing record
      const destroyField = document.getElementById(`dvhs_destroy_${id}`);
      if (destroyField) {
        destroyField.value = '1';
        row.style.display = 'none';
      }
    } else {
      // For new entries without ID, just remove the row
      row.remove();
    }
    
    // If no more DVHs, show the empty state
    const tableBody = document.getElementById('dvhs-table-body');
    if (tableBody) {
      const visibleRows = Array.from(tableBody.children).filter(row => row.style.display !== 'none');
      if (visibleRows.length === 0) {
        const container = document.getElementById('dvhs-table-container');
        if (container) {
          // Remove existing table
          const existingTable = container.querySelector('table');
          if (existingTable) {
            existingTable.remove();
          }
          // Add empty state message
          container.innerHTML = `
            <div class="text-center py-4 text-gray-500">
              No hay DVHs cargados. Agrega uno para comenzar.
            </div>
          `;
        }
      }
    }
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

    // requires input validation
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
      { key: 'glasscutting2_color', label: 'Color del cristal 2' }
    ];
    const missingField = requiredFields.find(field => !values[field.key] || values[field.key].trim() === '');
    if (missingField) {
      alert('Falta rellenar la siguiente columna: ' + missingField.label);
      return;
    }
    
    // Ensure table exists before adding row
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
    
    // Create new table row
    const tr = document.createElement("tr");
    tr.className = "divide-x divide-gray-200";
    
    // Populate row with DVH data and delete button
    tr.innerHTML = `
      <td class='px-4 py-2 text-center'>${values.typology || ''}</td>
      <td class='px-4 py-2 text-center'>${values.innertube || ''}</td>
      <td class='px-4 py-2 text-center'>${values.height || ''}</td>
      <td class='px-4 py-2 text-center'>${values.width || ''}</td>
      <td class='px-4 py-2 text-center'>${values.glasscutting1_type || ''} / ${values.glasscutting1_thickness || ''} / ${values.glasscutting1_color || ''}</td>
      <td class='px-4 py-2 text-center'>${values.glasscutting2_type || ''} / ${values.glasscutting2_thickness || ''} / ${values.glasscutting2_color || ''}</td>
      <td class='px-4 py-2 text-center'>${price.toFixed(2) || ''}</td>
      <td class='px-4 py-2 text-right space-x-2'>
        <button type="button" class="edit-dvh bg-blue-500 text-white px-3 py-1 rounded" data-temp-id="">Editar</button>
        <button type="button" class="delete-dvh bg-red-500 text-white px-3 py-1 rounded">Eliminar</button>
      </td>
    `;
    
    dvhTbody.appendChild(tr);
    
    // Update project totals if function exists
    setTimeout(() => {
      if (typeof window.updateProjectTotals === 'function') {
        window.updateProjectTotals();
      }
    }, 100);
    
    // Create hidden form inputs for Rails form submission
    // DVH requires more fields due to dual glass configuration
    const hiddenDiv = document.createElement("div");
    hiddenDiv.style.display = "none";
    hiddenDiv.className = "dvh-hidden-row";
    
    // Check if we're editing an existing project (has project_id in the URL)
    const urlParams = new URLSearchParams(window.location.search);
    const projectId = urlParams.get('project_id');
    
    // If we're editing, we need to use a unique index for each DVH
    // to prevent overwriting existing ones
    const index = projectId ? `new_${Date.now()}` : dvhIdCounter;
    
    hiddenDiv.innerHTML = `
      <input type="hidden" name="project[dvhs_attributes][${index}][typology]" value="${values.typology || ''}">
      <input type="hidden" name="project[dvhs_attributes][${index}][innertube]" value="${values.innertube || ''}">
      <input type="hidden" name="project[dvhs_attributes][${index}][height]" value="${values.height || ''}">
      <input type="hidden" name="project[dvhs_attributes][${index}][width]" value="${values.width || ''}">
      <input type="hidden" name="project[dvhs_attributes][${index}][glasscutting1_type]" value="${values.glasscutting1_type || ''}">
      <input type="hidden" name="project[dvhs_attributes][${index}][glasscutting1_thickness]" value="${values.glasscutting1_thickness || ''}">
      <input type="hidden" name="project[dvhs_attributes][${index}][glasscutting1_color]" value="${values.glasscutting1_color || ''}">
      <input type="hidden" name="project[dvhs_attributes][${index}][glasscutting2_type]" value="${values.glasscutting2_type || ''}">
      <input type="hidden" name="project[dvhs_attributes][${index}][glasscutting2_thickness]" value="${values.glasscutting2_thickness || ''}">
      <input type="hidden" name="project[dvhs_attributes][${index}][glasscutting2_color]" value="${values.glasscutting2_color || ''}">
      <input type="hidden" name="project[dvhs_attributes][${index}][price]" value="${price.toFixed(2)}">
      <input type="hidden" name="project[dvhs_attributes][${index}][_destroy]" value="0">
    `;
    
    document.getElementById("dvhs-hidden").appendChild(hiddenDiv);
    // Tag table row and edit button with temp id for inline editing
    tr.setAttribute('data-temp-id', index);
    const editBtn = tr.querySelector('.edit-dvh');
    if (editBtn) { editBtn.setAttribute('data-temp-id', index); }
    
    // Increment counter and remove form container
    dvhIdCounter++;
    container.remove();
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
    container.remove();
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

// Utility function to get price per square meter for specific glass configuration
// Searches the global GLASS_PRICES array populated from Rails backend
export function getDvhGlassPriceM2(type, thickness, color) {
  if (!window.GLASS_PRICES) return 0;
  const found = window.GLASS_PRICES.find(p =>
    p.glass_type === type && p.thickness === thickness && p.color === color
  );
  return found ? found.selling_price : 0;
}

// Calculate total innertube price including 4 fixed angles
// This matches the Ruby calculation in AppConfig.calculate_innertube_total_price
export function calculateInnertubeTotal(innertubeSize, perimeterM) {
  // Get price per linear meter (without angles)
  const pricePerMeter = window.INNERTUBE_PRICES ? (window.INNERTUBE_PRICES[innertubeSize] || 0) : 0;
  const linearCost = perimeterM * pricePerMeter;
  
  // Add fixed cost of 4 angles per DVH
  const anglePrice = window.SUPPLY_PRICES ? (window.SUPPLY_PRICES['Angulos'] || 0) : 0;
  const anglesCost = anglePrice * 4;  // Always 4 angles per DVH
  
  return linearCost + anglesCost;
}

// Calculates total price for DVH unit with two glass panes plus innertube cost
// Takes dimensions, specifications for both glass layers, and innertube size
export function getDvhTotalGlassPrice(height, width, glass1, glass2, innertubeSize) {
  // Calculate area in square meters for glass
  const area = (height * width) / 1000000;
  
  // Calculate perimeter in linear meters for innertube
  const perimeter = 2 * ((height / 1000) + (width / 1000));

  // Get price per square meter for each glass pane
  const price1 = getDvhGlassPriceM2(glass1.type, glass1.thickness, glass1.color);
  const price2 = getDvhGlassPriceM2(glass2.type, glass2.thickness, glass2.color);

  // Calculate total prices
  const glassPrice = area * (price1 + price2);
  const innertubePrice = calculateInnertubeTotal(innertubeSize, perimeter);

  // Return total price for glass panes plus innertube (including 4 angles)
  return glassPrice + innertubePrice;
}