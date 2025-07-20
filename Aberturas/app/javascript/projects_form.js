// This script manages dynamic addition and removal of Glasscutting and DVH fields in the project form.
// It ensures that event listeners are not duplicated on Turbo navigation, and handles confirm/delete actions for each dynamic row.

// Global variables
let glasscuttingIdCounter = 1;
let glasscuttingTable = null;
let glasscuttingTbody = null;
let dvhIdCounter = 1;
let dvhTable = null;
let dvhTbody = null;
let isListenerRegistered = false;

// Configuración de tipos, grosores y colores válidos
const GLASS_OPTIONS = {
  "Laminado": {
    grosores: ["3+3", "4+4", "5+5"],
    colores: ["incoloro", "esmerilado"]
  },
  "Float": {
    grosores: ["5mm"],
    colores: ["incoloro", "gris", "bronce"]
  },
  "Cool lite": {
    grosores: ["4+4"],
    colores: ["incoloro"]
  }
};

function updateGlassSelects(container) {
  const typeSelect = container.querySelector('.glass-type-select');
  const thicknessSelect = container.querySelector('.glass-thickness-select');
  const colorSelect = container.querySelector('.glass-color-select');

  if (!typeSelect || !thicknessSelect || !colorSelect) return;

  function fillOptions() {
    const tipo = typeSelect.value;
    thicknessSelect.innerHTML = '<option value="">Seleccionar</option>';
    colorSelect.innerHTML = '<option value="">Seleccionar</option>';
    if (GLASS_OPTIONS[tipo]) {
      GLASS_OPTIONS[tipo].grosores.forEach(g => {
        const opt = document.createElement('option');
        opt.value = g;
        opt.textContent = g;
        thicknessSelect.appendChild(opt);
      });
      GLASS_OPTIONS[tipo].colores.forEach(c => {
        const opt = document.createElement('option');
        opt.value = c;
        opt.textContent = c;
        colorSelect.appendChild(opt);
      });
    }
  }

  // Inicializar según valor actual
  fillOptions();

  // Cuando cambia el tipo, actualizar grosores y colores
  typeSelect.addEventListener('change', fillOptions);
}

function setupAllGlassSelects() {
  document.querySelectorAll('.glasscutting-fields').forEach(updateGlassSelects);
}

function ensureGlasscuttingTable() {
  // Check if table already exists in the container
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

function removeGlasscuttingTableIfEmpty() {
  if (glasscuttingTbody && glasscuttingTbody.children.length === 0) {
    if (glasscuttingTable && glasscuttingTable.parentNode) {
      glasscuttingTable.parentNode.removeChild(glasscuttingTable);
    }
    glasscuttingTable = null;
    glasscuttingTbody = null;
  }
}

function ensureDvhTable() {
  // Check if table already exists in the container
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

function removeDvhTableIfEmpty() {
  if (dvhTbody && dvhTbody.children.length === 0) {
    if (dvhTable && dvhTable.parentNode) {
      dvhTable.parentNode.removeChild(dvhTable);
    }
    dvhTable = null;
    dvhTbody = null;
  }
}

// Event delegation for confirm and delete buttons (works for dynamically added elements)
function handleGlasscuttingAndDvhEvents(e) {
  // Handle confirm button click for Glasscutting - add to table
  if (e.target.classList.contains("confirm-glass")) {
    const container = e.target.closest(".glasscutting-fields");
    const inputs = container.querySelectorAll("input, select");
    // Recolectar valores
    const values = {};
    inputs.forEach(input => {
      values[input.name.split("[").pop().replace("]", "")] = input.value;
    });
    // Crear tabla si no existe
    ensureGlasscuttingTable();
    // Agregar fila a la tabla
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
    glasscuttingIdCounter++;
    container.remove();
    return;
  }

  // Handle delete button click for Glasscutting - removes the row or view
  if (e.target.classList.contains("delete-glass")) {
    const tr = e.target.closest("tr");
    if (tr) {
      tr.remove();
      removeGlasscuttingTableIfEmpty();
      return;
    }
    const container = e.target.closest(".glasscutting-fields") || e.target.closest(".glasscutting-view");
    if (container) { container.remove(); return; }
  }

  // Handle cancel button click for Glasscutting - removes the row (before confirm)
  if (e.target.classList.contains("cancel-glass")) {
    const container = e.target.closest(".glasscutting-fields");
    container.remove();
    return;
  }

  // Handle confirm button click for DVH - add to table
  if (e.target.classList.contains("confirm-dvh")) {
    const container = e.target.closest(".dvh-fields");
    const inputs = container.querySelectorAll("input");
    // Recolectar valores
    const values = {};
    inputs.forEach(input => {
      values[input.name.split("[").pop().replace("]", "")] = input.value;
    });
    // Crear tabla si no existe
    ensureDvhTable();
    // Agregar fila a la tabla
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
    dvhIdCounter++;
    container.remove();
    return;
  }

  // Handle delete button click for DVH - removes the row or view
  if (e.target.classList.contains("delete-dvh")) {
    const tr = e.target.closest("tr");
    if (tr) {
      tr.remove();
      removeDvhTableIfEmpty();
      return;
    }
    const container = e.target.closest(".dvh-fields") || e.target.closest(".dvh-view");
    if (container) { container.remove(); return; }
  }

  // Handle cancel button click for DVH - removes the row (before confirm)
  if (e.target.classList.contains("cancel-dvh")) {
    const container = e.target.closest(".dvh-fields");
    container.remove();
    return;
  }
}

// Register event listener only once globally
if (!isListenerRegistered) {
  document.addEventListener("click", handleGlasscuttingAndDvhEvents);
  isListenerRegistered = true;
}

document.addEventListener('turbo:load', () => {
  // Reset variables for new page load
  glasscuttingIdCounter = 1;
  glasscuttingTable = null;
  glasscuttingTbody = null;
  dvhIdCounter = 1;
  dvhTable = null;
  dvhTbody = null;

  // Remove previous listeners if any by replacing the button with its clone
  // (Prevents multiple event listeners from being attached on Turbo navigation)
  const addGlasscuttingBtn = document.getElementById('add-glasscutting');
  if (addGlasscuttingBtn) {
    addGlasscuttingBtn.replaceWith(addGlasscuttingBtn.cloneNode(true));
  }
  const addDvhBtn = document.getElementById('add-dvh');
  if (addDvhBtn) {
    addDvhBtn.replaceWith(addDvhBtn.cloneNode(true));
  }

  // Now re-select the new buttons (with no previous listeners)
  const newAddGlasscuttingBtn = document.getElementById('add-glasscutting');
  if (newAddGlasscuttingBtn) {
    // Add a new Glasscutting row from the template when clicked
    newAddGlasscuttingBtn.addEventListener('click', () => {
      const template = document.getElementById('glasscutting-template').content.cloneNode(true);
      document.getElementById('glasscuttings-wrapper').appendChild(template);
      setTimeout(() => {
        // Solo el último agregado
        const fields = document.querySelectorAll('.glasscutting-fields');
        updateGlassSelects(fields[fields.length - 1]);
      }, 0);
    });
  }

  const newAddDvhBtn = document.getElementById('add-dvh');
  if (newAddDvhBtn) {
    // Add a new DVH row from the template when clicked
    newAddDvhBtn.addEventListener('click', () => {
      const template = document.getElementById('dvh-template').content.cloneNode(true);
      document.getElementById('dvhs-wrapper').appendChild(template);
    });
  }

  // Inicializar selects dependientes en los ya existentes
  setupAllGlassSelects();
});
