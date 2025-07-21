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
  // Confirmar
  if (e.target.classList.contains("confirm-glass")) {
    const container = e.target.closest(".glasscutting-fields");
    const inputs = container.querySelectorAll("input, select");
    const values = {};
    inputs.forEach(input => {
      values[input.name.split("[").pop().replace("]", "")] = input.value;
    });
    ensureGlasscuttingTable();
    const tr = document.createElement("tr");
    tr.className = "divide-x divide-gray-200";
    tr.innerHTML = `
      <td class='px-2 py-1'>${glasscuttingIdCounter}</td>
      <td class='px-2 py-1'>${values.glass_type || ''}</td>
      <td class='px-2 py-1'>${values.thickness || ''}</td>
      <td class='px-2 py-1'>${values.color || ''}</td>
      <td class='px-2 py-1'>${values.location || ''}</td>
      <td class='px-2 py-1'>${values.height || ''}</td>
      <td class='px-2 py-1'>${values.width || ''}</td>
      <td class='px-2 py-1'></td>
      <td class='px-2 py-1 text-right'><button type="button" class="delete-glass bg-red-500 text-white px-3 py-1 rounded">Eliminar</button></td>
    `;
    glasscuttingTbody.appendChild(tr);
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