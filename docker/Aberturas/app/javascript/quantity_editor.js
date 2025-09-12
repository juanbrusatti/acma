// quantity_editor.js
// Maneja la edición inline de cantidades de planchas

document.addEventListener('turbo:load', function() {
  setupQuantityEditors();
});

function setupQuantityEditors() {
  // Configurar botones +/- para entrar en modo edición
  document.querySelectorAll('.minus-btn, .plus-btn').forEach(btn => {
    btn.addEventListener('click', function(e) {
      e.preventDefault();
      const controls = this.closest('.quantity-controls');
      const display = controls.querySelector('.quantity-display');
      const edit = controls.querySelector('.quantity-edit');
      const input = edit.querySelector('.quantity-input');
      
      // Ocultar vista normal y mostrar vista de edición
      display.classList.add('hidden');
      edit.classList.remove('hidden');
      
      // Enfocar el input
      input.focus();
      input.select();
    });
  });

  // Configurar botones +/- en modo edición
  document.querySelectorAll('.minus-btn-edit').forEach(btn => {
    btn.addEventListener('click', function(e) {
      e.preventDefault();
      const input = this.parentElement.querySelector('.quantity-input');
      const currentValue = parseInt(input.value) || 0;
      if (currentValue > 0) {
        input.value = currentValue - 1;
      }
    });
  });

  document.querySelectorAll('.plus-btn-edit').forEach(btn => {
    btn.addEventListener('click', function(e) {
      e.preventDefault();
      const input = this.parentElement.querySelector('.quantity-input');
      const currentValue = parseInt(input.value) || 0;
      input.value = currentValue + 1;
    });
  });

  // Configurar botón confirmar
  document.querySelectorAll('.confirm-btn').forEach(btn => {
    btn.addEventListener('click', function(e) {
      e.preventDefault();
      const controls = this.closest('.quantity-controls');
      const glassplateId = controls.getAttribute('data-glassplate-id');
      const input = controls.querySelector('.quantity-input');
      const newQuantity = parseInt(input.value) || 0;
      
      if (newQuantity < 0) {
        alert('La cantidad no puede ser menor a 0');
        return;
      }
      
      // Enviar actualización al servidor
      updateQuantity(glassplateId, newQuantity, controls);
    });
  });

  // Configurar botón cancelar
  document.querySelectorAll('.cancel-btn').forEach(btn => {
    btn.addEventListener('click', function(e) {
      e.preventDefault();
      const controls = this.closest('.quantity-controls');
      const originalQuantity = controls.getAttribute('data-current-quantity');
      const input = controls.querySelector('.quantity-input');
      
      // Restaurar valor original
      input.value = originalQuantity;
      
      // Volver a vista normal
      const display = controls.querySelector('.quantity-display');
      const edit = controls.querySelector('.quantity-edit');
      display.classList.remove('hidden');
      edit.classList.add('hidden');
    });
  });

  // Permitir confirmar con Enter y cancelar con Escape
  document.querySelectorAll('.quantity-input').forEach(input => {
    input.addEventListener('keydown', function(e) {
      const controls = this.closest('.quantity-controls');
      
      if (e.key === 'Enter') {
        e.preventDefault();
        const confirmBtn = controls.querySelector('.confirm-btn');
        confirmBtn.click();
      } else if (e.key === 'Escape') {
        e.preventDefault();
        const cancelBtn = controls.querySelector('.cancel-btn');
        cancelBtn.click();
      }
    });
  });
}

function updateQuantity(glassplateId, newQuantity, controls) {
  const csrfToken = document.querySelector('meta[name="csrf-token"]')?.getAttribute('content');
  
  fetch(`/glassplates/${glassplateId}`, {
    method: 'PATCH',
    headers: {
      'Content-Type': 'application/json',
      'X-CSRF-Token': csrfToken,
      'Accept': 'application/json'
    },
    body: JSON.stringify({
      glassplate: {
        quantity: newQuantity
      }
    })
  })
  .then(response => {
    if (response.ok) {
      return response.json();
    } else {
      throw new Error('Error al actualizar la cantidad');
    }
  })
  .then(data => {
    // Actualizar la vista
    const display = controls.querySelector('.quantity-display');
    const edit = controls.querySelector('.quantity-edit');
    const quantityValue = display.querySelector('.quantity-value');
    
    // Actualizar valores
    quantityValue.textContent = newQuantity;
    controls.setAttribute('data-current-quantity', newQuantity);
    
    // Volver a vista normal
    display.classList.remove('hidden');
    edit.classList.add('hidden');
    
    // Mostrar mensaje de éxito
    showSuccessMessage('Cantidad actualizada exitosamente');
  })
  .catch(error => {
    console.error('Error:', error);
    alert('Error al actualizar la cantidad. Por favor, inténtalo de nuevo.');
    
    // Restaurar valor original en caso de error
    const originalQuantity = controls.getAttribute('data-current-quantity');
    const input = controls.querySelector('.quantity-input');
    input.value = originalQuantity;
  });
}

function showSuccessMessage(message) {
  // Crear mensaje de éxito temporal
  const successDiv = document.createElement('div');
  successDiv.className = 'fixed top-4 right-4 bg-green-100 border border-green-400 text-green-700 px-4 py-3 rounded z-50';
  successDiv.textContent = message;
  
  document.body.appendChild(successDiv);
  
  // Remover después de 3 segundos
  setTimeout(() => {
    if (successDiv.parentNode) {
      successDiv.parentNode.removeChild(successDiv);
    }
  }, 3000);
}
