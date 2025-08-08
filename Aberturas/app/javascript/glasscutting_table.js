// Glass Cutting Table Module
// Manages dynamic table creation and manipulation for glass cutting entries in projects
import { updateGlassSelects } from "glasscutting_selects";

// Global variables to track table state and unique IDs
let glasscuttingIdCounter = 1;
let glasscuttingTable = null;
let glasscuttingTbody = null;

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
          // Add empty state message
          container.innerHTML = `
            <div class="text-center py-4 text-gray-500">
              No hay vidrios simples cargados. Agrega uno para comenzar.
            </div>
          `;
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
    
    // Ensure table exists before adding row
    ensureGlasscuttingTable();
    
    // Create new table row
    const tr = document.createElement("tr");
    
    // Calculate price based on dimensions and glass type
    const price_m2 = getPriceM2(values.glass_type, values.thickness, values.color);
    const area_m2 = (parseFloat(values.height) / 1000) * (parseFloat(values.width) / 1000);
    const price = Math.round(area_m2 * price_m2 * 100) / 100; // Round to 2 decimals
    
    tr.className = "divide-x divide-gray-200";
    
    // Populate row with data and delete button
    tr.innerHTML = `
      <td class='px-4 py-2 text-center'>${values.typology || ''}</td>
      <td class='px-4 py-2 text-center'>${values.glass_type || ''}</td>
      <td class='px-4 py-2 text-center'>${values.thickness || ''}</td>
      <td class='px-4 py-2 text-center'>${values.color || ''}</td>
      <td class='px-4 py-2 text-center'>${values.height || ''}</td>
      <td class='px-4 py-2 text-center'>${values.width || ''}</td>
      <td class='px-4 py-2 text-center'>${price.toFixed(2) || ''}</td>
      <td class='px-4 py-2 text-right'><button type="button" class="delete-glass bg-red-500 text-white px-3 py-1 rounded">Eliminar</button></td>
    `;
    
    glasscuttingTbody.appendChild(tr);
    
    // Update project totals if function exists
    setTimeout(() => {
      if (typeof window.updateProjectTotals === 'function') {
        window.updateProjectTotals();
      }
    }, 100);
    
    // Create hidden form inputs for Rails form submission
    const hiddenDiv = document.createElement("div");
    hiddenDiv.style.display = "none";
    hiddenDiv.className = "glasscutting-hidden-row";
    
    // Generate a unique ID for the new glasscutting
    const newId = `new_${Date.now()}`;
    
    // Create the hidden inputs for the form
    hiddenDiv.innerHTML = `
      <input type="hidden" name="project[glasscuttings_attributes][${newId}][_destroy]" value="0">
      <input type="hidden" name="project[glasscuttings_attributes][${newId}][typology]" value="${values.typology || ''}">
      <input type="hidden" name="project[glasscuttings_attributes][${newId}][glass_type]" value="${values.glass_type || ''}">
      <input type="hidden" name="project[glasscuttings_attributes][${newId}][thickness]" value="${values.thickness || ''}">
      <input type="hidden" name="project[glasscuttings_attributes][${newId}][color]" value="${values.color || ''}">
      <input type="hidden" name="project[glasscuttings_attributes][${newId}][height]" value="${values.height || ''}">
      <input type="hidden" name="project[glasscuttings_attributes][${newId}][width]" value="${values.width || ''}">
      <input type="hidden" name="project[glasscuttings_attributes][${newId}][price]" value="${price.toFixed(2)}">
    `;
    
    // Add a data attribute to the row to identify it for deletion
    tr.setAttribute('data-temp-id', newId);
    
    // Add delete functionality for the new row
    const deleteButton = tr.querySelector('.delete-glass');
    if (deleteButton) {
      deleteButton.addEventListener('click', function(e) {
        e.preventDefault();
        const tempId = tr.getAttribute('data-temp-id');
        const destroyInput = document.querySelector(`input[name="project[glasscuttings_attributes][${tempId}][_destroy]"]`);
        if (destroyInput) {
          destroyInput.value = '1';
        }
        tr.remove();
        removeGlasscuttingTableIfEmpty();
      });
    }
    document.getElementById("glasscuttings-hidden").appendChild(hiddenDiv);
    
    // Increment counter and remove form container
    glasscuttingIdCounter++;
    container.remove();
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
    container.remove();
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

// Utility function to get price per square meter for specific glass configuration
// Searches the global GLASS_PRICES array populated from Rails backend
function getPriceM2(type, thickness, color) {
  if (!window.GLASS_PRICES) return 0;
  const found = window.GLASS_PRICES.find(p =>
    p.glass_type === type && p.thickness === thickness && p.color === color
  );
  return found ? found.selling_price : 0;
}