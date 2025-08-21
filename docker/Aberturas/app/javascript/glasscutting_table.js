// Glass Cutting Table Module
// Manages dynamic table creation and manipulation for glass cutting entries in projects
import { updateGlassSelects } from "glasscutting_selects";
import { getGlassPriceM2, requireFields, validateQuantity } from "utils";

// Global variables to track table state and unique IDs
let glasscuttingIdCounter = 1;
let glasscuttingTable = null;
let glasscuttingTbody = null;

// Pure builder for table row and hidden inputs for a glasscutting record
function buildGlasscuttingRow(values, price, index) {
  const newId = `new_${Date.now()}_${index}`;
  
  const tr = document.createElement("tr");
  tr.className = "divide-x divide-gray-200";
  tr.innerHTML = `
    <td class='px-4 py-2 text-center'>${values.typology || ''}</td>
    <td class='px-4 py-2 text-center'>${values.glass_type || ''}</td>
    <td class='px-4 py-2 text-center'>${values.thickness || ''}</td>
    <td class='px-4 py-2 text-center'>${values.color || ''}</td>
    <td class='px-4 py-2 text-center'>${values.height || ''}</td>
    <td class='px-4 py-2 text-center'>${values.width || ''}</td>
    <td class='px-4 py-2 text-center'>${values.type_opening || ''}</td>
    <td class='px-4 py-2 text-center'>$${price.toFixed(2) || ''}</td>
    <td class='px-4 py-2 text-center space-x-2'>
      <div class="flex space-x-1 justify-center">
        <button type="button" class="edit-glasscutting bg-blue-500 text-white px-2 py-1 rounded text-xs hover:bg-blue-600" data-temp-id="${newId}">Editar</button>
        <button type="button" class="delete-glass bg-red-500 text-white px-2 py-1 rounded text-xs hover:bg-red-600">Eliminar</button>
      </div>    
    </td>
  `;

  const hiddenDiv = document.createElement("div");
  hiddenDiv.style.display = "none";
  hiddenDiv.className = "glasscutting-hidden-row";
  hiddenDiv.innerHTML = `
    <input type="hidden" name="project[glasscuttings_attributes][${newId}][_destroy]" value="0">
    <input type="hidden" name="project[glasscuttings_attributes][${newId}][typology]" value="${values.typology || ''}">
    <input type="hidden" name="project[glasscuttings_attributes][${newId}][glass_type]" value="${values.glass_type || ''}">
    <input type="hidden" name="project[glasscuttings_attributes][${newId}][thickness]" value="${values.thickness || ''}">
    <input type="hidden" name="project[glasscuttings_attributes][${newId}][color]" value="${values.color || ''}">
    <input type="hidden" name="project[glasscuttings_attributes][${newId}][height]" value="${values.height || ''}">
    <input type="hidden" name="project[glasscuttings_attributes][${newId}][width]" value="${values.width || ''}">
    <input type="hidden" name="project[glasscuttings_attributes][${newId}][type_opening]" value="${values.type_opening || ''}">
    <input type="hidden" name="project[glasscuttings_attributes][${newId}][price]" value="${price.toFixed(2)}">
  `;

  tr.setAttribute('data-temp-id', newId);

  return { tr, hiddenDiv, tempId: newId };
}

// Ensures the glass cutting table exists in the DOM
// Creates the table structure if it doesn't exist, or references existing one
export function ensureGlasscuttingTable() {
  const container = document.getElementById('glasscuttings-table-container');
  const existingTable = container.querySelector('table');
  
  // If table already exists, just reference it
  if (existingTable) {
    glasscuttingTable = existingTable;
    glasscuttingTbody = existingTable.querySelector('tbody');
    return;
  }
  
  // Create new table if it doesn't exist
  if (!glasscuttingTable) {
    glasscuttingTable = document.createElement('table');
    glasscuttingTable.className = 'min-w-full text-xs text-gray-700 border';
    
    // Create table header with column definitions
    glasscuttingTable.innerHTML = `
      <thead>
        <tr class='bg-gray-50 text-gray-500'>
          <th class='px-4 py-2 text-center'>TIPOLOGIA</th>
          <th class='px-6 py-2 text-center'>TIPO</th>
          <th class='px-4 py-2 text-center'>GROSOR</th>
          <th class='px-4 py-2 text-center'>COLOR</th>
          <th class='px-4 py-2 text-center'>ALTO</th>
          <th class='px-4 py-2 text-center'>ANCHO</th>
          <th class='px-4 py-2 text-center'>ABERTURA</th>
          <th class='px-4 py-2 text-center'>PRECIO</th>
        </tr>
      </thead>
    `;
    
    // Create and append table body
    glasscuttingTbody = document.createElement('tbody');
    glasscuttingTbody.id = 'glasscuttings-table-body';
    glasscuttingTable.appendChild(glasscuttingTbody);
    container.appendChild(glasscuttingTable);
  }
}

// Removes the table from DOM if it's empty (no rows)
// Helps keep the interface clean when no glass cutting entries exist
export function removeGlasscuttingTableIfEmpty() {
  if (glasscuttingTbody && glasscuttingTbody.children.length === 0) {
    if (glasscuttingTable && glasscuttingTable.parentNode) {
      glasscuttingTable.parentNode.removeChild(glasscuttingTable);
    }
    // Reset references to null
    glasscuttingTable = null;
    glasscuttingTbody = null;
  }
}

// Main event handler for glass cutting related actions
// Handles confirm, delete, and cancel operations
export function handleGlasscuttingEvents(e) {
  // EDIT: Handle edit buttons for existing glasscuttings
  if (e.target.closest('.edit-glasscutting')) {
    const button = e.target.closest('.edit-glasscutting');
    const id = button.getAttribute('data-id');
    const row = button.closest('tr');
    const tempId = button.getAttribute('data-temp-id') || (row && row.getAttribute('data-temp-id'));
    
    if (id || tempId) {
      // Read current values from row
      const typology = row.querySelector('td:nth-child(1)').textContent.trim();
      const glassType = row.querySelector('td:nth-child(2)').textContent.trim();
      const thickness = row.querySelector('td:nth-child(3)').textContent.trim();
      const color = row.querySelector('td:nth-child(4)').textContent.trim();
      const height = row.querySelector('td:nth-child(5)').textContent.trim();
      const width = row.querySelector('td:nth-child(6)').textContent.trim();
      const type_opening = row.querySelector('td:nth-child(7)').textContent.trim();

      // Hide the row and show edit form using the same template as add
      row.style.display = 'none';

      const tpl = document.getElementById('glasscutting-template');
      if (!tpl) { return; }
      const fragment = tpl.content.cloneNode(true);
      const editContainer = fragment.querySelector('.glasscutting-fields');
      editContainer.classList.add('glasscutting-edit-form');

      // Prefill fields
      const typologyNumberInput = editContainer.querySelector('.typology-number-input');
      const typologyHidden = editContainer.querySelector('.typology-hidden-field');
      const numberOnly = typology.replace(/^V/i, '');
      if (typologyNumberInput) typologyNumberInput.value = numberOnly;
      if (typologyHidden) typologyHidden.value = typology;

      const typeSelect = editContainer.querySelector('.glass-type-select');
      const thicknessSelect = editContainer.querySelector('.glass-thickness-select');
      const colorSelect = editContainer.querySelector('.glass-color-select');
      const heightInput = editContainer.querySelector('input[name="project[glasscuttings_attributes][][height]"]');
      const widthInput = editContainer.querySelector('input[name="project[glasscuttings_attributes][][width]"]');
      const type_openingSelect = editContainer.querySelector('select[name="project[glasscuttings_attributes][][type_opening]"]');

      if (typeSelect) typeSelect.value = glassType;
      // Populate dependent selects then set values in correct order
      if (editContainer) { updateGlassSelects(editContainer); }
      if (thicknessSelect) {
        thicknessSelect.value = thickness;
        // Trigger change to refresh color options for selected thickness
        thicknessSelect.dispatchEvent(new Event('change', { bubbles: true }));
      }
      if (colorSelect) {
        // If the desired color option isn't present yet, add it so it stays selected
        if (color && !Array.from(colorSelect.options).some(o => o.value === color)) {
          const opt = document.createElement('option');
          opt.value = color;
          opt.textContent = color;
          colorSelect.appendChild(opt);
        }
        colorSelect.value = color;
      }
      if (heightInput) heightInput.value = height;
      if (widthInput) widthInput.value = width;
      if (type_openingSelect) {
        type_openingSelect.value = type_opening;
      }

      // Change action buttons to save/cancel edit
      const confirmBtn = editContainer.querySelector('.confirm-glass');
      const cancelBtn = editContainer.querySelector('.cancel-glass');
      if (confirmBtn) {
        confirmBtn.classList.remove('confirm-glass');
        confirmBtn.classList.add('save-glasscutting-edit');
        confirmBtn.textContent = 'Guardar';
        if (id) confirmBtn.setAttribute('data-id', id);
        if (tempId) confirmBtn.setAttribute('data-temp-id', tempId);
      }
      if (cancelBtn) {
        cancelBtn.classList.remove('cancel-glass');
        cancelBtn.classList.add('cancel-glasscutting-edit');
        cancelBtn.textContent = 'Cancelar';
      }

      // Insert the edit form before the row inside a full-width table row
      const editTr = document.createElement('tr');
      editTr.className = 'glasscutting-edit-row';
      const editTd = document.createElement('td');
      // Span all columns in the table
      editTd.colSpan = row.children.length;
      editTd.style.padding = '12px';
      editTd.appendChild(editContainer);
      editTr.appendChild(editTd);
      row.parentNode.insertBefore(editTr, row);
    }
    return;
  }
  
  // SAVE: Handle save button for glasscutting edit
  if (e.target.closest('.save-glasscutting-edit')) {
    const editContainer = e.target.closest('.glasscutting-edit-form');
    const editRow = editContainer.closest('tr.glasscutting-edit-row');
    const row = editRow ? editRow.nextElementSibling : null;
    if (!row) { return; }

    // Get values from form
    const typologyHidden = editContainer.querySelector('.typology-hidden-field');
    const typeSelect = editContainer.querySelector('.glass-type-select');
    const thicknessSelect = editContainer.querySelector('.glass-thickness-select');
    const colorSelect = editContainer.querySelector('.glass-color-select');
    const heightInput = editContainer.querySelector('input[name="project[glasscuttings_attributes][][height]"]');
    const widthInput = editContainer.querySelector('input[name="project[glasscuttings_attributes][][width]"]');
    const type_openingSelect = editContainer.querySelector('select[name="project[glasscuttings_attributes][][type_opening]"]');

    const newValues = {
      typology: typologyHidden ? typologyHidden.value : '',
      glass_type: typeSelect ? typeSelect.value : '',
      thickness: thicknessSelect ? thicknessSelect.value : '',
      color: colorSelect ? colorSelect.value : '',
      height: heightInput ? heightInput.value : '',
      width: widthInput ? widthInput.value : '',
      type_opening: type_openingSelect ? type_openingSelect.value : ''
    };

    // Recalculate price
    const price_m2 = getGlassPriceM2(newValues.glass_type, newValues.thickness, newValues.color);
    const area_m2 = (parseFloat(newValues.height) / 1000) * (parseFloat(newValues.width) / 1000);
    const price = Math.round(area_m2 * price_m2 * 100) / 100;

    // Update table cells
    row.querySelector('td:nth-child(1)').textContent = newValues.typology || '';
    row.querySelector('td:nth-child(2)').textContent = newValues.glass_type || '';
    row.querySelector('td:nth-child(3)').textContent = newValues.thickness || '';
    row.querySelector('td:nth-child(4)').textContent = newValues.color || '';
    row.querySelector('td:nth-child(5)').textContent = newValues.height || '';
    row.querySelector('td:nth-child(6)').textContent = newValues.width || '';
    row.querySelector('td:nth-child(7)').textContent = newValues.type_opening || '';
    row.querySelector('td:nth-child(8)').textContent = price.toFixed(2);

    // Update hidden inputs for existing or temp record
    const id = e.target.getAttribute('data-id');
    const tempId = e.target.getAttribute('data-temp-id') || (row && row.getAttribute('data-temp-id'));
    if (id) {
      const setByName = (field, value) => {
        const input = document.querySelector(`input[name="project[glasscuttings_attributes][${id}][${field}]"]`);
        if (input) input.value = value;
      };
      setByName('typology', newValues.typology);
      setByName('glass_type', newValues.glass_type);
      setByName('thickness', newValues.thickness);
      setByName('color', newValues.color);
      setByName('height', newValues.height);
      setByName('width', newValues.width);
      setByName('type_opening', newValues.type_opening);
      setByName('price', price.toFixed(2));
    } else if (tempId) {
      const setByName = (field, value) => {
        const input = document.querySelector(`input[name="project[glasscuttings_attributes][${tempId}][${field}]"]`);
        if (input) input.value = value;
      };
      setByName('typology', newValues.typology);
      setByName('glass_type', newValues.glass_type);
      setByName('thickness', newValues.thickness);
      setByName('color', newValues.color);
      setByName('height', newValues.height);
      setByName('width', newValues.width);
      setByName('type_opening', newValues.type_opening);
      setByName('price', price.toFixed(2));
    }

    // Show the row again and remove form
    row.style.display = '';
    if (editRow && editRow.parentNode) { editRow.parentNode.removeChild(editRow); }

    // Update totals
    setTimeout(() => {
      if (typeof window.updateProjectTotals === 'function') {
        window.updateProjectTotals();
      }
    }, 50);

    return;
  }
  
  // CANCEL: Handle cancel button for glasscutting edit
  if (e.target.closest('.cancel-glasscutting-edit')) {
    const editContainer = e.target.closest('.glasscutting-edit-form');
    const editRow = editContainer.closest('tr.glasscutting-edit-row');
    const row = editRow ? editRow.nextElementSibling : null;
    if (row) { row.style.display = ''; }
    if (editRow && editRow.parentNode) { editRow.parentNode.removeChild(editRow); }
    return;
  }
  
  // DELETE: Handle delete buttons for existing glasscuttings
  if (e.target.closest('.delete-glasscutting')) {
    const button = e.target.closest('.delete-glasscutting');
    const id = button.getAttribute('data-id');
    const row = button.closest('tr');
    
    if (id) {
      // Mark for destruction instead of removing, in case it's an existing record
      const destroyField = document.getElementById(`glasscuttings_destroy_${id}`);
      if (destroyField) {
        destroyField.value = '1';
        row.style.display = 'none';
      }
    } else {
      // For new entries without ID, just remove the row
      row.remove();
    }
    
    // If no more glasscuttings, show the empty state
    const tableBody = document.getElementById('glasscuttings-table-body');
    if (tableBody) {
      const visibleRows = Array.from(tableBody.children).filter(row => row.style.display !== 'none');
      if (visibleRows.length === 0) {
        const container = document.getElementById('glasscuttings-table-container');
        if (container) {
          // Remove existing table
          const existingTable = container.querySelector('table');
          if (existingTable) {
            existingTable.remove();
          }
        }
      }
    }
    return;
  }
  // CONFIRM: Add new glass cutting entry to table
  if (e.target.classList.contains("confirm-glass")) {
    const container = e.target.closest(".glasscutting-fields");
    
    // Before processing, ensure typology hidden field is updated
    const typologyNumberInput = container.querySelector('.typology-number-input');
    const typologyHidden = container.querySelector('.typology-hidden-field');
    if (typologyNumberInput && typologyHidden && typologyNumberInput.value) {
      typologyHidden.value = "V" + typologyNumberInput.value;
    }
    
    const inputs = container.querySelectorAll("input, select");
    
    // Extract values from form inputs
    const values = {};
    inputs.forEach(input => {
      if (input.name) {
        const fieldName = input.name.split("[").pop().replace("]", "");
        values[fieldName] = input.value;
      }
    });
    
    // Get quantity value from the quantity input (which doesn't have a name)
    const quantityInput = container.querySelector('.quantity-input');
    values.quantity = quantityInput ? quantityInput.value : '';
    
    const requiredFields = [
      { key: 'typology', label: 'Tipología' },
      { key: 'glass_type', label: 'Tipo' },
      { key: 'thickness', label: 'Grosor' },
      { key: 'color', label: 'Color' },
      { key: 'height', label: 'Alto' },
      { key: 'width', label: 'Ancho' },
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

    const quantity = parseInt(values.quantity)
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
    ensureGlasscuttingTable();
    
    // Calculate price based on dimensions and glass type
    const price_m2 = getGlassPriceM2(values.glass_type, values.thickness, values.color);
    const area_m2 = (parseFloat(values.height) / 1000) * (parseFloat(values.width) / 1000);
    const price = Math.round(area_m2 * price_m2 * 100) / 100; // Round to 2 decimals
    
    // Create multiple rows based on quantity
    for (let i = 0; i < quantity; i++) {
      const { tr, hiddenDiv, tempId } = buildGlasscuttingRow(values, price, i);
      glasscuttingTbody.appendChild(tr);

      console.log('Created glasscutting row with tempId:', tempId);
      console.log('Hidden div HTML:', hiddenDiv.innerHTML);

      // Add delete functionality for the new row
      const deleteButton = tr.querySelector('.delete-glass');
      if (deleteButton) {
        deleteButton.addEventListener('click', function(e) {
          e.preventDefault();
          const destroyInput = document.querySelector(`input[name="project[glasscuttings_attributes][${tempId}][_destroy]"]`);
          if (destroyInput) {
            destroyInput.value = '1';
          }
          tr.remove();
          removeGlasscuttingTableIfEmpty();
        });
      }

      document.getElementById("glasscuttings-hidden").appendChild(hiddenDiv);
      glasscuttingIdCounter++;
    }
    
    // Update project totals if function exists
    setTimeout(() => {
      if (typeof window.updateProjectTotals === 'function') {
        window.updateProjectTotals();
      }
    }, 100);
    
    // Remove form container
    console.log('Removing glasscutting form container');
    container.remove();
    console.log('Form container removed, checking for remaining forms...');
    const remainingForms = document.querySelectorAll('#glasscuttings-wrapper .glasscutting-fields');
    console.log('Remaining forms after removal:', remainingForms.length);
    return;
  }
  
  // DELETE: Remove glass cutting entry from table
  if (e.target.classList.contains("delete-glass")) {
    const tr = e.target.closest("tr");
    if (tr) {
      tr.remove();
      removeGlasscuttingTableIfEmpty();
      
      // Update project totals after deletion
      setTimeout(() => {
        if (typeof window.updateProjectTotals === 'function') {
          window.updateProjectTotals();
        }
      }, 100);
      
      // Remove corresponding hidden form inputs
      const hiddenRows = document.querySelectorAll("#glasscuttings-hidden .glasscutting-hidden-row");
      if (hiddenRows.length > 0) hiddenRows[hiddenRows.length - 1].remove();
      return;
    }
    
    // Handle deletion from form containers
    const container = e.target.closest(".glasscutting-fields") || e.target.closest(".glasscutting-view");
    if (container) { container.remove(); return; }
  }
  
  // CANCEL: Remove form without adding entry
  if (e.target.classList.contains("cancel-glass")) {
    const container = e.target.closest(".glasscutting-fields");
    console.log('Canceling glasscutting form, removing container');
    container.remove();
    console.log('Cancel form container removed');
    return;
  }
}

// Resets all module variables to initial state
// Used when starting fresh or clearing data
export function resetGlasscuttingTableVars() {
  glasscuttingIdCounter = 1;
  glasscuttingTable = null;
  glasscuttingTbody = null;
}

// Price lookup moved to utils.getGlassPriceM2