// glasscutting_table.js
import { updateGlassSelects } from "glasscutting_selects";

let glasscuttingIdCounter = 1;
let glasscuttingTable = null;
let glasscuttingTbody = null;

export function ensureGlasscuttingTable() {
  const container = document.getElementById('glasscuttings-table-container');
  const existingTable = container.querySelector('table');
  if (existingTable) {
    glasscuttingTable = existingTable;
    glasscuttingTbody = existingTable.querySelector('tbody');
    return;
  }
  if (!glasscuttingTable) {
    glasscuttingTable = document.createElement('table');
    glasscuttingTable.className = 'min-w-full text-xs text-gray-700 border';
    glasscuttingTable.innerHTML = `
      <thead>
        <tr class='bg-gray-50 text-gray-500'>
          <th class='px-2 py-1 text-left'>ID</th>
          <th class='px-2 py-1 text-left'>TIPO</th>
          <th class='px-2 py-1 text-left'>ESPESOR</th>
          <th class='px-2 py-1 text-left'>COLOR</th>
          <th class='px-2 py-1 text-left'>UBICACIÓN</th>
          <th class='px-2 py-1 text-left'>ALTO</th>
          <th class='px-2 py-1 text-left'>ANCHO</th>
          <th class='px-2 py-1 text-left'>PRECIO</th>
          <th class='px-2 py-1 text-left'></th>
        </tr>
      </thead>
    `;
    glasscuttingTbody = document.createElement('tbody');
    glasscuttingTbody.id = 'glasscuttings-table-body';
    glasscuttingTable.appendChild(glasscuttingTbody);
    container.appendChild(glasscuttingTable);
  }
}

export function removeGlasscuttingTableIfEmpty() {
  if (glasscuttingTbody && glasscuttingTbody.children.length === 0) {
    if (glasscuttingTable && glasscuttingTable.parentNode) {
      glasscuttingTable.parentNode.removeChild(glasscuttingTable);
    }
    glasscuttingTable = null;
    glasscuttingTbody = null;
  }
}

export function handleGlasscuttingEvents(e) {
  // Confirm
  if (e.target.classList.contains("confirm-glass")) {
    const container = e.target.closest(".glasscutting-fields");
    const inputs = container.querySelectorAll("input, select");
    const values = {};
    inputs.forEach(input => {
      values[input.name.split("[").pop().replace("]", "")] = input.value;
    });
    ensureGlasscuttingTable();
    const tr = document.createElement("tr");
    const price_m2 = getPriceM2(values.glass_type, values.thickness, values.color);
    const area_m2 = (parseFloat(values.height) / 1000) * (parseFloat(values.width) / 1000);
    const price = Math.round(area_m2 * price_m2 * 100) / 100; // redondeamos a 2 decimales
    tr.className = "divide-x divide-gray-200";
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
    updateSubtotalPrice();
    // Agregar inputs ocultos
    const hiddenDiv = document.createElement("div");
    hiddenDiv.style.display = "none";
    hiddenDiv.className = "glasscutting-hidden-row";
    hiddenDiv.innerHTML = `
      <input type="hidden" name="project[glasscuttings_attributes][][glass_type]" value="${values.glass_type || ''}">
      <input type="hidden" name="project[glasscuttings_attributes][][thickness]" value="${values.thickness || ''}">
      <input type="hidden" name="project[glasscuttings_attributes][][color]" value="${values.color || ''}">
      <input type="hidden" name="project[glasscuttings_attributes][][location]" value="${values.location || ''}">
      <input type="hidden" name="project[glasscuttings_attributes][][height]" value="${values.height || ''}">
      <input type="hidden" name="project[glasscuttings_attributes][][width]" value="${values.width || ''}">
    `;
    document.getElementById("glasscuttings-hidden").appendChild(hiddenDiv);
    glasscuttingIdCounter++;
    container.remove();
    return;
  }
  // Eliminar
  if (e.target.classList.contains("delete-glass")) {
    const tr = e.target.closest("tr");
    if (tr) {
      tr.remove();
      updateSubtotalPrice();
      removeGlasscuttingTableIfEmpty();
      // Eliminar también el set de inputs ocultos correspondiente
      const hiddenRows = document.querySelectorAll("#glasscuttings-hidden .glasscutting-hidden-row");
      if (hiddenRows.length > 0) hiddenRows[hiddenRows.length - 1].remove();
      return;
    }
    const container = e.target.closest(".glasscutting-fields") || e.target.closest(".glasscutting-view");
    if (container) { container.remove(); return; }
  }
  // Cancelar
  if (e.target.classList.contains("cancel-glass")) {
    const container = e.target.closest(".glasscutting-fields");
    container.remove();
    return;
  }
}

export function resetGlasscuttingTableVars() {
  glasscuttingIdCounter = 1;
  glasscuttingTable = null;
  glasscuttingTbody = null;
}

// Returns the price per m2 for a given type, thickness, and color from the global GLASS_PRICES array
function getPriceM2(type, thickness, color) {
  if (!window.GLASS_PRICES) return 0;
  const found = window.GLASS_PRICES.find(p =>
    p.glass_type === type && p.thickness === thickness && p.color === color
  );
  return found ? found.price_m2 : 0;
}

// Calculates the subtotal by summing the price of each confirmed glasscutting row
// Then updates the subtotal, IVA, and total in the DOM
function updateSubtotalPrice() {
  let subtotal = 0;
  // Iterate over each row in the glasscuttings table and sum the prices
  document.querySelectorAll('#glasscuttings-table-body tr').forEach(tr => {
    const priceCell = tr.querySelector('td:nth-child(8)');
    if (priceCell) {
      const price = parseFloat(priceCell.textContent.replace(',', '.')) || 0;
      subtotal += price;
    }
  });
  // Update the subtotal in the DOM
  const subtotalPriceElem = document.getElementById('subtotal-price');
  if (subtotalPriceElem) {
    subtotalPriceElem.textContent = '$' + subtotal.toFixed(2);
  }
  // Update IVA and total as well
  updateTotalWithIVA(subtotal);
}

// Calculates and updates the IVA (21% of subtotal) in the DOM
export function updateIVA(subtotal) {
  const iva = subtotal * 0.21;
  const ivaElem = document.getElementById('iva-value');
  if (ivaElem) {
    ivaElem.textContent = '$' + iva.toFixed(2);
  }
  return iva;
}

// Calculates and updates the total price (subtotal + IVA) in the DOM
export function updateTotalWithIVA(subtotal) {
  const iva = updateIVA(subtotal);
  const total = subtotal + iva;
  const totalElem = document.getElementById('price-total');
  if (totalElem) {
    totalElem.textContent = '$' + total.toFixed(2);
  }
  return total;
}