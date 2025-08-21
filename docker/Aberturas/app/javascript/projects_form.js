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
  // Solo ejecutar en páginas de formulario (new/edit), no en show
  const projectForm = document.getElementById('project-form');
  if (projectForm) {
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
  }
});

function updateProjectTotals() {
  let subtotal = 0;
  
  console.log('=== updateProjectTotals called ===');

  document.querySelectorAll('#glasscuttings-table-body tr').forEach(tr => {
    if (tr.style.display === 'none') return; // Ignore hidden (deleted) rows
    const priceCell = tr.querySelector('td:nth-child(8)');
    if (priceCell) {
      let priceText = priceCell.textContent.trim();
      priceText = priceText.replace(/[$,]/g, '');
      const price = parseFloat(priceText) || 0;
      subtotal += price;
    }
  });

  document.querySelectorAll('#dvhs-table-body tr').forEach(tr => {
    if (tr.style.display === 'none') return; // Ignore hidden (deleted) rows
    const priceCell = tr.querySelector('td:nth-child(8)');
    if (priceCell) {
      let priceText = priceCell.textContent.trim();
      priceText = priceText.replace(/[$,]/g, '');
      const price = parseFloat(priceText) || 0;
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
      console.log('Form submit event triggered');
      console.log('Form action:', this.action);
      console.log('Form method:', this.method);
      
      // Only check for forms that are actually open and need confirmation
      // This prevents interference with the normal add/edit process
      const hasUnconfirmedForms = document.querySelectorAll('#glasscuttings-wrapper .glasscutting-fields, #dvhs-wrapper .dvh-fields, .glasscutting-edit-form, .dvh-edit-form').length > 0;
      
      console.log('Has unconfirmed forms:', hasUnconfirmedForms);
      
      if (hasUnconfirmedForms) {
        console.log('Preventing form submission - unconfirmed forms detected');
        const swalConfig = window.getSwalConfig();
        window.Swal.fire({
          ...swalConfig,
          title: 'Faltan vidrios por confirmar',
        });
        event.preventDefault();
      } else {
        console.log('Form submission allowed - no unconfirmed forms');
      }
    });
  }
});