// projects_form.js (entrypoint)
import { setupAllGlassSelects, updateGlassSelects } from "glasscutting_selects";
import { ensureGlasscuttingTable, removeGlasscuttingTableIfEmpty, handleGlasscuttingEvents, resetGlasscuttingTableVars } from "glasscutting_table";
import { ensureDvhTable, removeDvhTableIfEmpty, handleDvhEvents, resetDvhTableVars } from "dvh_table";

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
    });
  }

  // Inicializar selects dependientes en los ya existentes
  setupAllGlassSelects();
});
