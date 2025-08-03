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
          <th class='px-2 py-1 text-left'>ID</th>
          <th class='px-2 py-1 text-left'>TIPO</th>
          <th class='px-2 py-1 text-left'>GROSOR</th>
          <th class='px-2 py-1 text-left'>COLOR</th>
          <th class='px-2 py-1 text-left'>UBICACIÓN</th>
          <th class='px-2 py-1 text-left'>ALTO</th>
          <th class='px-2 py-1 text-left'>ANCHO</th>
          <th class='px-2 py-1 text-left'>PRECIO</th>
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
  // CONFIRM: Add new glass cutting entry to table
  if (e.target.classList.contains("confirm-glass")) {
    const container = e.target.closest(".glasscutting-fields");
    const inputs = container.querySelectorAll("input, select");
    
    // Extract values from form inputs
    const values = {};
    inputs.forEach(input => {
      values[input.name.split("[").pop().replace("]", "")] = input.value;
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
      <td class='px-2 py-1'>${glasscuttingIdCounter}</td>
      <td class='px-2 py-1'>${values.glass_type || ''}</td>
      <td class='px-2 py-1'>${values.thickness || ''}</td>
      <td class='px-2 py-1'>${values.color || ''}</td>
      <td class='px-2 py-1'>${values.location || ''}</td>
      <td class='px-2 py-1'>${values.height || ''}</td>
      <td class='px-2 py-1'>${values.width || ''}</td>
      <td class='px-2 py-1'>${price || ''}</td>
      <td class='px-2 py-1 text-right'><button type="button" class="delete-glass bg-red-500 text-white px-3 py-1 rounded">Eliminar</button></td>
    `;
    
    glasscuttingTbody.appendChild(tr);
    
    // Update project totals if function exists
    if (typeof window.updateProjectTotals === 'function') window.updateProjectTotals();
    
    // Create hidden form inputs for Rails form submission
    const hiddenDiv = document.createElement("div");
    hiddenDiv.style.display = "none";
    hiddenDiv.className = "glasscutting-hidden-row";
    // Use glasscutting counter as unique index for nested attributes
    const index = glasscuttingIdCounter;
    hiddenDiv.innerHTML = `
      <input type="hidden" name="project[glasscuttings_attributes][${index}][glass_type]" value="${values.glass_type || ''}">
      <input type="hidden" name="project[glasscuttings_attributes][${index}][thickness]" value="${values.thickness || ''}">
      <input type="hidden" name="project[glasscuttings_attributes][${index}][color]" value="${values.color || ''}">
      <input type="hidden" name="project[glasscuttings_attributes][${index}][location]" value="${values.location || ''}">
      <input type="hidden" name="project[glasscuttings_attributes][${index}][height]" value="${values.height || ''}">
      <input type="hidden" name="project[glasscuttings_attributes][${index}][width]" value="${values.width || ''}">
      <input type="hidden" name="project[glasscuttings_attributes][${index}][price]" value="${price.toFixed(2)}">
    `;
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
      if (typeof window.updateProjectTotals === 'function') window.updateProjectTotals();
      
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