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

// Add input event listener for real-time typology updates
function handleInputEvents(e) {
  if (e.target.classList.contains('typology-number-input')) {
    const container = e.target.closest('.glasscutting-fields, .dvh-fields');
    if (container) {
      const typologyHidden = container.querySelector('.typology-hidden-field');
      if (typologyHidden) {
        typologyHidden.value = e.target.value ? "V" + e.target.value : "";
      }
    }
  }
}

if (!window._projectsFormEventRegistered) {
  console.log('Registering project form events');
  document.addEventListener("click", handleAllEvents);
  document.addEventListener("input", handleInputEvents);
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
  console.log('DVH button found:', newAddDvhBtn);
  if (newAddDvhBtn) {
    newAddDvhBtn.addEventListener('click', () => {
      console.log('DVH button clicked');
      const template = document.getElementById('dvh-template');
      console.log('DVH Template found:', template);
      const templateContent = template.content.cloneNode(true);
      console.log('DVH Template content:', templateContent);
      const wrapper = document.getElementById('dvhs-wrapper');
      console.log('DVH Wrapper found:', wrapper);
      wrapper.appendChild(templateContent);
      setTimeout(() => {
        // Only the last added one
        const fields = document.querySelectorAll('.dvh-fields');
        console.log('DVH Fields found:', fields.length);
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
  
  console.log('=== updateProjectTotals called ===');

  // Sum all simple glass prices (column 7, not 8)
  document.querySelectorAll('#glasscuttings-table-body tr').forEach(tr => {
    const priceCell = tr.querySelector('td:nth-child(7)');
    if (priceCell) {
      // Clean the text: remove $, commas, and handle decimal points
      let priceText = priceCell.textContent.trim();
      priceText = priceText.replace(/[$,]/g, ''); // Remove $ and commas
      const price = parseFloat(priceText) || 0;
      console.log('Glasscutting price:', priceText, '->', price);
      subtotal += price;
    }
  });

  // Sum all DVH prices (column 7, not 8)
  document.querySelectorAll('#dvhs-table-body tr').forEach(tr => {
    const priceCell = tr.querySelector('td:nth-child(7)');
    if (priceCell) {
      // Clean the text: remove $, commas, and handle decimal points
      let priceText = priceCell.textContent.trim();
      priceText = priceText.replace(/[$,]/g, ''); // Remove $ and commas
      const price = parseFloat(priceText) || 0;
      console.log('DVH price:', priceText, '->', price);
      subtotal += price;
    }
  });
  
  console.log('Total subtotal:', subtotal);

  // Try to update both possible element IDs for subtotal
  const subtotalPriceElem = document.getElementById('subtotal-price') || document.getElementById('project-price-view');
  if (subtotalPriceElem) {
    subtotalPriceElem.textContent = '$' + subtotal.toFixed(2);
    console.log('Updated subtotal element:', subtotalPriceElem.id, 'to:', '$' + subtotal.toFixed(2));
  } else {
    console.log('No subtotal element found');
  }

  // Calculate and update VAT (21%)
  const iva = subtotal * 0.21;
  const ivaElem = document.getElementById('iva-value') || document.getElementById('project-iva-view');
  if (ivaElem) {
    ivaElem.textContent = '$' + iva.toFixed(2);
    console.log('Updated IVA element:', ivaElem.id, 'to:', '$' + iva.toFixed(2));
  } else {
    console.log('No IVA element found');
  }

  // Calculate and update total
  const total = subtotal + iva;
  const totalElem = document.getElementById('price-total') || document.getElementById('project-price-iva-view');
  if (totalElem) {
    totalElem.textContent = '$' + total.toFixed(2);
    console.log('Updated total element:', totalElem.id, 'to:', '$' + total.toFixed(2));
  } else {
    console.log('No total element found');
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
document.addEventListener('turbo:load', () => {
  const projectForm = document.getElementById('project-form');
  if (projectForm) {
    projectForm.addEventListener('submit', function(event) {
    const openGlasscuttingForms = document.querySelectorAll('.glasscutting-fields:not(.hidden) input:not([disabled])');
    const openDvhForms = document.querySelectorAll('.dvh-fields:not(.hidden) input:not([disabled])');
    if (openGlasscuttingForms.length > 0 || openDvhForms.length > 0) {
      if (window.Swal) {
        window.Swal.fire({
          toast: true,
          position: 'top-end',
          icon: 'warning',
          title: 'Faltan vidrios por confirmar',
          showConfirmButton: false,
          timer: 4000,
          timerProgressBar: true
        });
      }
      event.preventDefault();
    }
    });
  }
});