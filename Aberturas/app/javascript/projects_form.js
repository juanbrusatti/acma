// JS for dynamic field addition
  // Add event listener for adding new glasscutting fields
document.getElementById('add-glasscutting').addEventListener('click', () => {
    const template = document.getElementById('glasscutting-template').content.cloneNode(true);
    document.getElementById('glasscuttings-wrapper').appendChild(template);
});

// Add event listener for adding new DVH fields
document.getElementById('add-dvh').addEventListener('click', () => {
    const template = document.getElementById('dvh-template').content.cloneNode(true);
    document.getElementById('dvhs-wrapper').appendChild(template);
});

// Event delegation for confirm and delete buttons
document.addEventListener("click", function (e) {
// Handle confirm button click - locks the fields and replaces with delete button
    if (e.target.classList.contains("confirm-glass")) {
        const container = e.target.closest(".glasscutting-fields");
        const inputs = container.querySelectorAll("input");

        // Disable all input fields to lock the values
        inputs.forEach(input => input.setAttribute("readonly", true));

        // Replace confirm button with delete button
        const confirmButton = e.target;
        const deleteButton = document.createElement("button");
        deleteButton.type = "button";
        deleteButton.textContent = "Eliminar";
        deleteButton.className = "delete-glass bg-red-500 text-white px-3 py-1 rounded mt-4";

        confirmButton.replaceWith(deleteButton);
    }

    // Handle delete button click - removes the entire glasscutting row
    if (e.target.classList.contains("delete-glass")) {
        const container = e.target.closest(".glasscutting-fields");
        container.remove();
    }
});

document.addEventListener("click", function (e) {
    // Confirm DVH
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

    // Remove DVH
    if (e.target.classList.contains("delete-dvh")) {
        const container = e.target.closest(".dvh-fields");
        container.remove();
    }
});