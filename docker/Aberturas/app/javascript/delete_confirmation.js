// delete_confirmation.js
// Maneja las confirmaciones de eliminación con mensajes personalizados

document.addEventListener('turbo:load', function() {
  // Configurar confirmaciones para botones de eliminar
  setupDeleteConfirmations();
});

function setupDeleteConfirmations() {
  // Buscar todos los botones de eliminar
  const deleteButtons = document.querySelectorAll('.delete-btn');
  
  deleteButtons.forEach(button => {
    button.addEventListener('click', function(e) {
      e.preventDefault();
      
      const itemType = this.getAttribute('data-type') === 'plancha' ? 'la plancha' : 'el retazo';
      const itemName = getItemName(this);
      
      const message = `¿Estás seguro de que quieres eliminar ${itemType} "${itemName}"?\n\n⚠️ ADVERTENCIA: Esta acción no se puede deshacer.\n\n• El elemento será eliminado permanentemente de la base de datos\n• Se perderá toda la información asociada\n• Esta acción es irreversible`;
      
      if (confirm(message)) {
        // Si confirma, proceder con la eliminación usando fetch
        const url = this.getAttribute('data-url');
        
        // Crear un formulario temporal para enviar la petición DELETE
        const form = document.createElement('form');
        form.method = 'POST';
        form.action = url;
        
        // Agregar el token CSRF
        const csrfToken = document.querySelector('meta[name="csrf-token"]')?.getAttribute('content');
        if (csrfToken) {
          const csrfInput = document.createElement('input');
          csrfInput.type = 'hidden';
          csrfInput.name = 'authenticity_token';
          csrfInput.value = csrfToken;
          form.appendChild(csrfInput);
        }
        
        // Agregar el campo _method para simular DELETE
        const methodInput = document.createElement('input');
        methodInput.type = 'hidden';
        methodInput.name = '_method';
        methodInput.value = 'DELETE';
        form.appendChild(methodInput);
        
        // Agregar el formulario al DOM y enviarlo
        document.body.appendChild(form);
        form.submit();
        document.body.removeChild(form);
      }
    });
  });
}

function getItemName(button) {
  // Intentar obtener el nombre del elemento desde el contexto
  const row = button.closest('tr');
  if (row) {
    // Buscar en las celdas de la fila para encontrar información identificativa
    const cells = row.querySelectorAll('td');
    
    // Para glassplates: mostrar tipo + grosor + color
    if (button.getAttribute('data-type') === 'plancha') {
      const type = cells[0]?.textContent?.trim();
      const thickness = cells[1]?.textContent?.trim();
      const color = cells[2]?.textContent?.trim();
      return `${type} ${thickness} ${color}`;
    }
    
    // Para scraps: mostrar referencia
    if (button.getAttribute('data-type') === 'retazo') {
      const ref = cells[0]?.textContent?.trim();
      return ref || 'sin referencia';
    }
  }
  
  return 'sin nombre';
}

// Función para confirmaciones programáticas
function confirmDelete(itemType, itemName, callback) {
  const message = `¿Estás seguro de que quieres eliminar ${itemType} "${itemName}"?\n\n⚠️ ADVERTENCIA: Esta acción no se puede deshacer.\n\n• El elemento será eliminado permanentemente de la base de datos\n• Se perderá toda la información asociada\n• Esta acción es irreversible`;
  
  if (confirm(message)) {
    callback();
  }
}
