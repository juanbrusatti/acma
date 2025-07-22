// dvh_table.js
let dvhIdCounter = 1;
let dvhTable = null;
let dvhTbody = null;

export function ensureDvhTable() {
  const container = document.getElementById('dvhs-table-container');
  const existingTable = container.querySelector('table');
  if (existingTable) {
    dvhTable = existingTable;
    dvhTbody = existingTable.querySelector('tbody');
    return;
  }
  if (!dvhTable) {
    dvhTable = document.createElement('table');
    dvhTable.className = 'min-w-full text-xs text-gray-700 border';
    dvhTable.innerHTML = `
      <thead>
        <tr class='bg-gray-50 text-gray-500'>
          <th class='px-2 py-1 text-left'>ID</th>
          <th class='px-2 py-1 text-left'>CÁMARA</th>
          <th class='px-2 py-1 text-left'>UBICACIÓN</th>
          <th class='px-2 py-1 text-left'>ALTO</th>
          <th class='px-2 py-1 text-left'>ANCHO</th>
          <th class='px-2 py-1 text-left'>CRISTAL 1</th>
          <th class='px-2 py-1 text-left'>CRISTAL 2</th>
          <th class='px-2 py-1 text-left'></th>
        </tr>
      </thead>
    `;
    dvhTbody = document.createElement('tbody');
    dvhTbody.id = 'dvhs-table-body';
    dvhTable.appendChild(dvhTbody);
    container.appendChild(dvhTable);
  }
}

export function removeDvhTableIfEmpty() {
  if (dvhTbody && dvhTbody.children.length === 0) {
    if (dvhTable && dvhTable.parentNode) {
      dvhTable.parentNode.removeChild(dvhTable);
    }
    dvhTable = null;
    dvhTbody = null;
  }
}

export function handleDvhEvents(e) {
  // Confirmar
  if (e.target.classList.contains("confirm-dvh")) {
    const container = e.target.closest(".dvh-fields");
    const inputs = container.querySelectorAll("input");
    const values = {};
    inputs.forEach(input => {
      values[input.name.split("[").pop().replace("]", "")] = input.value;
    });
    ensureDvhTable();
    const tr = document.createElement("tr");
    tr.className = "divide-x divide-gray-200";
    tr.innerHTML = `
      <td class='px-2 py-1'>${dvhIdCounter}</td>
      <td class='px-2 py-1'>${values.innertube || ''}</td>
      <td class='px-2 py-1'>${values.location || ''}</td>
      <td class='px-2 py-1'>${values.height || ''}</td>
      <td class='px-2 py-1'>${values.width || ''}</td>
      <td class='px-2 py-1'>${values.glasscutting1_type || ''} / ${values.glasscutting1_thickness || ''} / ${values.glasscutting1_color || ''}</td>
      <td class='px-2 py-1'>${values.glasscutting2_type || ''} / ${values.glasscutting2_thickness || ''} / ${values.glasscutting2_color || ''}</td>
      <td class='px-2 py-1 text-right'><button type="button" class="delete-dvh bg-red-500 text-white px-3 py-1 rounded">Eliminar</button></td>
    `;
    dvhTbody.appendChild(tr);
    // Agregar inputs ocultos
    const hiddenDiv = document.createElement("div");
    hiddenDiv.style.display = "none";
    hiddenDiv.className = "dvh-hidden-row";
    hiddenDiv.innerHTML = `
      <input type="hidden" name="project[dvhs_attributes][][innertube]" value="${values.innertube || ''}">
      <input type="hidden" name="project[dvhs_attributes][][location]" value="${values.location || ''}">
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
    dvhIdCounter++;
    container.remove();
    return;
  }
  // Eliminar
  if (e.target.classList.contains("delete-dvh")) {
    const tr = e.target.closest("tr");
    if (tr) {
      tr.remove();
      removeDvhTableIfEmpty();
      // Eliminar también el set de inputs ocultos correspondiente
      const hiddenRows = document.querySelectorAll("#dvhs-hidden .dvh-hidden-row");
      if (hiddenRows.length > 0) hiddenRows[hiddenRows.length - 1].remove();
      return;
    }
    const container = e.target.closest(".dvh-fields") || e.target.closest(".dvh-view");
    if (container) { container.remove(); return; }
  }
  // Cancelar
  if (e.target.classList.contains("cancel-dvh")) {
    const container = e.target.closest(".dvh-fields");
    container.remove();
    return;
  }
}

export function resetDvhTableVars() {
  dvhIdCounter = 1;
  dvhTable = null;
  dvhTbody = null;
}