// DVH (Double Glazing) Table Module
// Manages dynamic table creation and manipulation for double-glazed window entries in projects
// DVH stands for "Doble Vidriado Hermético" (Hermetic Double Glazing)

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
          <th class='px-2 py-1 text-left'>TIPOLOGÍA</th>
          <th class='px-2 py-1 text-left'>CÁMARA</th>
          <th class='px-2 py-1 text-left'>ALTO</th>
          <th class='px-2 py-1 text-left'>ANCHO</th>
          <th class='px-2 py-1 text-left'>CRISTAL 1</th>
          <th class='px-2 py-1 text-left'>CRISTAL 2</th>
          <th class='px-2 py-1 text-left'>PRECIO</th>
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
      <td class='px-2 py-1'>${values.typology || ''}</td>
      <td class='px-2 py-1'>${values.innertube || ''}</td>
      <td class='px-2 py-1'>${values.height || ''}</td>
      <td class='px-2 py-1'>${values.width || ''}</td>
      <td class='px-2 py-1'>${values.glasscutting1_type || ''} / ${values.glasscutting1_thickness || ''} / ${values.glasscutting1_color || ''}</td>
      <td class='px-2 py-1'>${values.glasscutting2_type || ''} / ${values.glasscutting2_thickness || ''} / ${values.glasscutting2_color || ''}</td>
      <td class='px-2 py-1'>${price.toFixed(2) || ''}</td>
      <td class='px-2 py-1 text-right'><button type="button" class="delete-dvh bg-red-500 text-white px-3 py-1 rounded">Eliminar</button></td>
    `;
    
    dvhTbody.appendChild(tr);
    
    // Update project totals if function exists
    if (typeof window.updateProjectTotals === 'function') window.updateProjectTotals();
    
    // Create hidden form inputs for Rails form submission
    // DVH requires more fields due to dual glass configuration
    const hiddenDiv = document.createElement("div");
    hiddenDiv.style.display = "none";
    hiddenDiv.className = "dvh-hidden-row";
    // Use DVH counter as unique index for nested attributes
    const index = dvhIdCounter;
    
    hiddenDiv.innerHTML = `
      <input type="hidden" name="project[dvhs_attributes][][typology]" value="${values.typology || ''}">
      <input type="hidden" name="project[dvhs_attributes][][innertube]" value="${values.innertube || ''}">
      <input type="hidden" name="project[dvhs_attributes][][height]" value="${values.height || ''}">
      <input type="hidden" name="project[dvhs_attributes][][width]" value="${values.width || ''}">
      <input type="hidden" name="project[dvhs_attributes][][glasscutting1_type]" value="${values.glasscutting1_type || ''}">
      <input type="hidden" name="project[dvhs_attributes][][glasscutting1_thickness]" value="${values.glasscutting1_thickness || ''}">
      <input type="hidden" name="project[dvhs_attributes][][glasscutting1_color]" value="${values.glasscutting1_color || ''}">
      <input type="hidden" name="project[dvhs_attributes][][glasscutting2_type]" value="${values.glasscutting2_type || ''}">
      <input type="hidden" name="project[dvhs_attributes][][glasscutting2_thickness]" value="${values.glasscutting2_thickness || ''}">
      <input type="hidden" name="project[dvhs_attributes][][glasscutting2_color]" value="${values.glasscutting2_color || ''}">
    `;
    
    document.getElementById("dvhs-hidden").appendChild(hiddenDiv);
    
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
      if (typeof window.updateProjectTotals === 'function') window.updateProjectTotals();
      
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