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
          <th class='px-2 py-1 text-left'>PRECIO</th>
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
    const fields = container.querySelectorAll("input, select");
    const values = {};
    fields.forEach(field => {
      // Si el campo no tiene name, lo salteamos
      if (!field.name) return;
      // Extraemos el nombre del atributo (por ejemplo, glasscutting1_type)
      const key = field.name.split("[").pop().replace("]", "");
      values[key] = field.value;
    });
    ensureDvhTable();
    const height = parseFloat(values.height) || 0;
    const width = parseFloat(values.width) || 0;
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
    const price = getDvhTotalGlassPrice(height, width, glass1, glass2);
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
      <td class='px-2 py-1'>${price.toFixed(2) || ''}</td>
      <td class='px-2 py-1 text-right'><button type="button" class="delete-dvh bg-red-500 text-white px-3 py-1 rounded">Eliminar</button></td>
    `;
    dvhTbody.appendChild(tr);
    if (typeof window.updateProjectTotals === 'function') window.updateProjectTotals();
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
      if (typeof window.updateProjectTotals === 'function') window.updateProjectTotals();
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

export function getDvhGlassPriceM2(type, thickness, color) {
  if (!window.GLASS_PRICES) return 0;
  const found = window.GLASS_PRICES.find(p =>
    p.glass_type === type && p.thickness === thickness && p.color === color
  );
  return found ? found.price_m2 : 0;
}

export function getDvhTotalGlassPrice(height, width, glass1, glass2) {
  // Área en m2
  const area = (height * width) / 1000000;

  // Precio por m2 de cada cristal
  const price1 = getDvhGlassPriceM2(glass1.type, glass1.thickness, glass1.color);
  const price2 = getDvhGlassPriceM2(glass2.type, glass2.thickness, glass2.color);

  // Precio total para ambos cristales
  return area * (price1 + price2);
}