// glasscutting_table.js
import { updateGlassSelects, GLASS_OPTIONS } from "glasscutting_selects";

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
      <td class='px-2 py-1 text-right'>
        <button type="button" class="edit-glass bg-blue-500 text-white px-3 py-1 rounded mr-2">Editar</button>
        <button type="button" class="delete-glass bg-red-500 text-white px-3 py-1 rounded">Eliminar</button>
      </td>
    `;
    glasscuttingTbody.appendChild(tr);
    if (typeof window.updateProjectTotals === 'function') window.updateProjectTotals();
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
  // Editar
  if (e.target.classList.contains("edit-glass")) {
    const tr = e.target.closest("tr");
    if (!tr) return;
    // Obtener valores actuales
    const tds = tr.querySelectorAll("td");
    const current = {
      glass_type: tds[1].textContent.trim(),
      thickness: tds[2].textContent.trim(),
      color: tds[3].textContent.trim(),
      location: tds[4].textContent.trim(),
      height: tds[5].textContent.trim(),
      width: tds[6].textContent.trim(),
      price: tds[7].textContent.trim()
    };
    // Guardar HTML original para cancelar
    tr._originalHTML = tr.innerHTML;
    // Reemplazar por selects dependientes y inputs
    // Opciones de tipo de vidrio
    const glassOptions = window.GLASS_OPTIONS || GLASS_OPTIONS;
    const glassTypes = Object.keys(glassOptions);
    // Opciones de ubicación (puedes ajustar según tu lógica)
    const locations = ["UMBRAL", "DINTEL", "JAMBA_I", "JAMBA_D"];
    // Helper para options
    function options(arr, selected) {
      return arr.map(opt => `<option value='${opt}'${opt === selected ? " selected" : ""}>${opt}</option>`).join("");
    }
    tr.innerHTML = `
      <td class='px-2 py-1'>${tds[0].textContent}</td>
      <td class='px-2 py-1'>
        <select class='edit-type w-full border rounded px-1'>
          <option value=''>Seleccionar</option>
          ${options(glassTypes, current.glass_type)}
        </select>
      </td>
      <td class='px-2 py-1'>
        <select class='edit-thickness w-full border rounded px-1'></select>
      </td>
      <td class='px-2 py-1'>
        <select class='edit-color w-full border rounded px-1'></select>
      </td>
      <td class='px-2 py-1'>
        <select class='edit-location w-full border rounded px-1'>
          <option value=''>Seleccionar</option>
          ${options(locations, current.location)}
        </select>
      </td>
      <td class='px-2 py-1'><input type='number' class='edit-height w-full border rounded px-1' value='${current.height}'></td>
      <td class='px-2 py-1'><input type='number' class='edit-width w-full border rounded px-1' value='${current.width}'></td>
      <td class='px-2 py-1'>${current.price}</td>
     <td class="px-2 py-1 text-right flex justify-end gap-2">
         <button type="button" class="save-glass bg-green-500 text-white px-3 py-1 rounded">Guardar</button>
         <button type="button" class="cancel-edit-glass bg-gray-300 text-black px-3 py-1 rounded">Cancelar</button>
     </td>

    `;
    // Llenar selects dependientes
    const typeSelect = tr.querySelector('.edit-type');
    const thicknessSelect = tr.querySelector('.edit-thickness');
    const colorSelect = tr.querySelector('.edit-color');
    function fillThicknessAndColor(init = false) {
      const tipo = typeSelect.value || current.glass_type;
      // Guardar el valor seleccionado por el usuario antes de actualizar
      const prevThickness = thicknessSelect.value;
      const prevColor = colorSelect.value;
      thicknessSelect.innerHTML = '<option value="">Seleccionar</option>';
      colorSelect.innerHTML = '<option value="">Seleccionar</option>';
      if (glassOptions[tipo]) {
        const grosores = Object.keys(glassOptions[tipo]);
        grosores.forEach(grosor => {
          thicknessSelect.innerHTML += `<option value='${grosor}'>${grosor}</option>`;
        });
        // Selección inicial para edición o mantener selección del usuario
        if (init && current.thickness) {
          thicknessSelect.value = current.thickness;
        } else if (prevThickness && grosores.includes(prevThickness)) {
          thicknessSelect.value = prevThickness;
        }
        const selectedThickness = thicknessSelect.value || current.thickness;
        const colores = glassOptions[tipo][selectedThickness] || [];
        colores.forEach(color => {
          colorSelect.innerHTML += `<option value='${color}'>${color}</option>`;
        });
        // Selección inicial para edición o mantener selección del usuario
        if (init && current.color) {
          colorSelect.value = current.color;
        } else if (prevColor && colores.includes(prevColor)) {
          colorSelect.value = prevColor;
        }
      }
    }
    typeSelect.addEventListener('change', () => {
      fillThicknessAndColor();
    });
    thicknessSelect.addEventListener('change', () => {
      fillThicknessAndColor();
    });
    fillThicknessAndColor(true);
    return;
  }

  // Guardar edición
  if (e.target.classList.contains("save-glass")) {
    const tr = e.target.closest("tr");
    if (!tr) return;
    // Obtener nuevos valores correctamente de selects e inputs
    const tds = tr.querySelectorAll("td");
    const newValues = {
      glass_type: tds[1].querySelector("select").value,
      thickness: tds[2].querySelector("select").value,
      color: tds[3].querySelector("select").value,
      location: tds[4].querySelector("select").value,
      height: tds[5].querySelector("input").value,
      width: tds[6].querySelector("input").value
    };
    // Recalcular precio si es necesario
    const price_m2 = getPriceM2(newValues.glass_type, newValues.thickness, newValues.color);
    const area_m2 = (parseFloat(newValues.height) / 1000) * (parseFloat(newValues.width) / 1000);
    const price = Math.round(area_m2 * price_m2 * 100) / 100;
    // Actualizar fila
    tr.innerHTML = `
      <td class='px-2 py-1'>${tds[0].textContent}</td>
      <td class='px-2 py-1'>${newValues.glass_type}</td>
      <td class='px-2 py-1'>${newValues.thickness}</td>
      <td class='px-2 py-1'>${newValues.color}</td>
      <td class='px-2 py-1'>${newValues.location}</td>
      <td class='px-2 py-1'>${newValues.height}</td>
      <td class='px-2 py-1'>${newValues.width}</td>
      <td class='px-2 py-1'>${price}</td>
      <td class='px-2 py-1 text-right'>
        <button type="button" class="edit-glass bg-blue-500 text-white px-3 py-1 rounded mr-2">Editar</button>
        <button type="button" class="delete-glass bg-red-500 text-white px-3 py-1 rounded">Eliminar</button>
      </td>
    `;
    if (typeof window.updateProjectTotals === 'function') window.updateProjectTotals();
    // Actualizar el div oculto correspondiente
    // Se asume que el índice de la fila en tbody corresponde al div oculto
    const rowIndex = Array.from(tr.parentNode.children).indexOf(tr);
    const hiddenRows = document.querySelectorAll("#glasscuttings-hidden .glasscutting-hidden-row");
    const hiddenDiv = hiddenRows[rowIndex];
    if (hiddenDiv) {
      const inputs = hiddenDiv.querySelectorAll("input");
      inputs.forEach(input => {
        if (input.name.includes("glass_type")) input.value = newValues.glass_type;
        if (input.name.includes("thickness")) input.value = newValues.thickness;
        if (input.name.includes("color")) input.value = newValues.color;
        if (input.name.includes("location")) input.value = newValues.location;
        if (input.name.includes("height")) input.value = newValues.height;
        if (input.name.includes("width")) input.value = newValues.width;
      });
    }
    return;
  }

  // Cancelar edición
  if (e.target.classList.contains("cancel-edit-glass")) {
    const tr = e.target.closest("tr");
    if (!tr || !tr._originalHTML) return;
    tr.innerHTML = tr._originalHTML;
    return;
  }
  // Eliminar
  if (e.target.classList.contains("delete-glass")) {
    const tr = e.target.closest("tr");
    if (tr) {
      tr.remove();
      removeGlasscuttingTableIfEmpty();
      if (typeof window.updateProjectTotals === 'function') window.updateProjectTotals();
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