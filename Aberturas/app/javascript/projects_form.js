// This script manages dynamic addition and removal of Glasscutting and DVH fields in the project form.
// It ensures that event listeners are not duplicated on Turbo navigation, and handles confirm/delete actions for each dynamic row.

document.addEventListener('turbo:load', () => {
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

  // Event delegation for confirm and delete buttons (works for dynamically added elements)
  document.addEventListener("click", function (e) {
    // Handle confirm button click for Glasscutting - locks the fields and replaces with delete button
    if (e.target.classList.contains("confirm-glass")) {
      const container = e.target.closest(".glasscutting-fields");
      const inputs = container.querySelectorAll("input");
      inputs.forEach(input => input.setAttribute("readonly", true));

      const confirmButton = e.target;
      const deleteButton = document.createElement("button");
      deleteButton.type = "button";
      deleteButton.textContent = "Eliminar";
      deleteButton.className = "delete-glass bg-red-500 text-white px-3 py-1 rounded mt-4";

      confirmButton.replaceWith(deleteButton);
    }

    // Handle delete button click for Glasscutting - removes the row
    if (e.target.classList.contains("delete-glass")) {
      const container = e.target.closest(".glasscutting-fields");
      container.remove();
    }

    // Handle confirm button click for DVH - locks the fields and replaces with delete button
    if (e.target.classList.contains("confirm-dvh")) {
      const container = e.target.closest(".dvh-fields");
      const inputs = container.querySelectorAll("input");
      inputs.forEach(input => input.setAttribute("readonly", true));

      const confirmButton = e.target;
      const deleteButton = document.createElement("button");
      deleteButton.type = "button";
      deleteButton.textContent = "Eliminar";
      deleteButton.className = "delete-dvh bg-red-500 text-white px-3 py-1 rounded mt-4";

      confirmButton.replaceWith(deleteButton);
    }

    // Handle delete button click for DVH - removes the row
    if (e.target.classList.contains("delete-dvh")) {
      const container = e.target.closest(".dvh-fields");
      container.remove();
    }
  });
});
  