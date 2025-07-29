// projects_form.js (entry point)
import { setupAllGlassSelects, updateGlassSelects } from "glasscutting_selects";
import { ensureGlasscuttingTable, removeGlasscuttingTableIfEmpty, handleGlasscuttingEvents, resetGlasscuttingTableVars } from "glasscutting_table";
import { ensureDvhTable, removeDvhTableIfEmpty, handleDvhEvents, resetDvhTableVars } from "dvh_table";
import { setupAllDvhGlassSelects, updateDvhGlassSelects } from "dvh_selects";

// Global event delegation
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
        // Only the last added one
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
        // Only the last added one
        const fields = document.querySelectorAll('.dvh-fields');
        updateDvhGlassSelects(fields[fields.length - 1], 'glasscutting1');
        updateDvhGlassSelects(fields[fields.length - 1], 'glasscutting2');
      }, 0);
    });
  }

  // Initialize dependent selects on existing ones
  setupAllGlassSelects();
  setupAllDvhGlassSelects();
  
  // Initialize project totals on page load
  setTimeout(() => {
    updateProjectTotals();
  }, 100);
});

function updateProjectTotals() {
  let subtotal = 0;

  // Sum all simple glass prices
  document.querySelectorAll('#glasscuttings-table-body tr').forEach(tr => {
    const priceCell = tr.querySelector('td:nth-child(8)');
    if (priceCell) {
      const price = parseFloat(priceCell.textContent.replace(',', '.')) || 0;
      subtotal += price;
    }
  });

  // Sum all DVH prices
  document.querySelectorAll('#dvhs-table-body tr').forEach(tr => {
    const priceCell = tr.querySelector('td:nth-child(8)');
    if (priceCell) {
      const price = parseFloat(priceCell.textContent.replace(',', '.')) || 0;
      subtotal += price;
    }
  });

  // Update subtotal
  const subtotalPriceElem = document.getElementById('subtotal-price');
  if (subtotalPriceElem) {
    subtotalPriceElem.textContent = '$' + subtotal.toFixed(2);
  }

  // Calculate and update VAT (21%)
  const iva = subtotal * 0.21;
  const ivaElem = document.getElementById('iva-value');
  if (ivaElem) {
    ivaElem.textContent = '$' + iva.toFixed(2);
  }

  // Calculate and update total
  const total = subtotal + iva;
  const totalElem = document.getElementById('price-total');
  if (totalElem) {
    totalElem.textContent = '$' + total.toFixed(2);
  }

  // Update hidden fields with the calculated prices
  const hiddenPriceField = document.getElementById('hidden-project-price');
  if (hiddenPriceField) {
    hiddenPriceField.value = total.toFixed(2);
  }
  
  const hiddenPriceWithoutIvaField = document.getElementById('hidden-project-price-without-iva');
  if (hiddenPriceWithoutIvaField) {
    hiddenPriceWithoutIvaField.value = subtotal.toFixed(2);
  }
}

window.updateProjectTotals = updateProjectTotals;
