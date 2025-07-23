// projects_form.js (entrypoint)
import { setupAllGlassSelects, updateGlassSelects } from "glasscutting_selects";
import { ensureGlasscuttingTable, removeGlasscuttingTableIfEmpty, handleGlasscuttingEvents, resetGlasscuttingTableVars } from "glasscutting_table";
import { ensureDvhTable, removeDvhTableIfEmpty, handleDvhEvents, resetDvhTableVars } from "dvh_table";
import { setupAllDvhGlassSelects, updateDvhGlassSelects } from "dvh_selects";

// Event delegation global
function handleAllEvents(e) {
  handleGlasscuttingEvents(e);
  handleDvhEvents(e);
}

if (!window._projectsFormEventRegistered) {
  document.addEventListener("click", handleAllEvents);
  window._projectsFormEventRegistered = true;
}

document.addEventListener('turbo:load', () => {
  // Reset variables for new page load
  resetGlasscuttingTableVars();
  resetDvhTableVars();

  // Remove previous listeners if any by replacing the button with its clone
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
    newAddDvhBtn.addEventListener('click', () => {
      const template = document.getElementById('dvh-template').content.cloneNode(true);
      document.getElementById('dvhs-wrapper').appendChild(template);
      setTimeout(() => {
        // Solo el último agregado
        const fields = document.querySelectorAll('.dvh-fields');
        updateDvhGlassSelects(fields[fields.length - 1], 'glasscutting1');
        updateDvhGlassSelects(fields[fields.length - 1], 'glasscutting2');
      }, 0);
    });
  }

  // Inicializar selects dependientes en los ya existentes
  setupAllGlassSelects();
  setupAllDvhGlassSelects();
});

function updateProjectTotals() {
  let subtotal = 0;

  // Sumar todos los precios de vidrios simples
  document.querySelectorAll('#glasscuttings-table-body tr').forEach(tr => {
    const priceCell = tr.querySelector('td:nth-child(8)');
    if (priceCell) {
      const price = parseFloat(priceCell.textContent.replace(',', '.')) || 0;
      subtotal += price;
    }
  });

  // Sumar todos los precios de DVH
  document.querySelectorAll('#dvhs-table-body tr').forEach(tr => {
    const priceCell = tr.querySelector('td:nth-child(8)');
    if (priceCell) {
      const price = parseFloat(priceCell.textContent.replace(',', '.')) || 0;
      subtotal += price;
    }
  });

  // Actualizar subtotal
  const subtotalPriceElem = document.getElementById('subtotal-price');
  if (subtotalPriceElem) {
    subtotalPriceElem.textContent = '$' + subtotal.toFixed(2);
  }

  // Calcular y actualizar IVA (21%)
  const iva = subtotal * 0.21;
  const ivaElem = document.getElementById('iva-value');
  if (ivaElem) {
    ivaElem.textContent = '$' + iva.toFixed(2);
  }

  // Calcular y actualizar total
  const total = subtotal + iva;
  const totalElem = document.getElementById('price-total');
  if (totalElem) {
    totalElem.textContent = '$' + total.toFixed(2);
  }
}

window.updateProjectTotals = updateProjectTotals;
