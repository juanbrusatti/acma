// confirmations.js
// Manejo de confirmaciones con SweetAlert2 para Rails con Turbo

import Swal from 'sweetalert2';

// Interceptar todos los enlaces y botones con data-confirm
document.addEventListener('turbo:load', function() {
  // Manejar enlaces con data-confirm
  document.querySelectorAll('a[data-confirm]').forEach(function(link) {
    link.addEventListener('click', function(e) {
      e.preventDefault();
      
      const confirmMessage = this.getAttribute('data-confirm');
      const href = this.getAttribute('href');
      const method = this.getAttribute('data-method') || 'get';
      
      Swal.fire({
        title: '¿Estás seguro?',
        text: confirmMessage.replace(/\n/g, '\n'),
        icon: 'warning',
        showCancelButton: true,
        confirmButtonColor: '#d33',
        cancelButtonColor: '#3085d6',
        confirmButtonText: 'Sí, eliminar',
        cancelButtonText: 'Cancelar',
        customClass: {
          popup: 'swal2-popup-custom'
        }
      }).then((result) => {
        if (result.isConfirmed) {
          // Crear un formulario para enviar la petición DELETE
          if (method.toLowerCase() === 'delete') {
            const form = document.createElement('form');
            form.method = 'POST';
            form.action = href;
            
            const methodInput = document.createElement('input');
            methodInput.type = 'hidden';
            methodInput.name = '_method';
            methodInput.value = 'DELETE';
            
            const csrfToken = document.querySelector('meta[name="csrf-token"]');
            if (csrfToken) {
              const csrfInput = document.createElement('input');
              csrfInput.type = 'hidden';
              csrfInput.name = 'authenticity_token';
              csrfInput.value = csrfToken.getAttribute('content');
              form.appendChild(csrfInput);
            }
            
            form.appendChild(methodInput);
            document.body.appendChild(form);
            form.submit();
          } else {
            // Para otros métodos, navegar normalmente
            window.location.href = href;
          }
        }
      });
    });
  });

  // Manejar botones con data-confirm
  document.querySelectorAll('button[data-confirm], input[data-confirm]').forEach(function(button) {
    button.addEventListener('click', function(e) {
      e.preventDefault();
      
      const confirmMessage = this.getAttribute('data-confirm');
      const form = this.closest('form');
      
      if (form) {
        Swal.fire({
          title: '¿Estás seguro?',
          text: confirmMessage.replace(/\n/g, '\n'),
          icon: 'warning',
          showCancelButton: true,
          confirmButtonColor: '#d33',
          cancelButtonColor: '#3085d6',
          confirmButtonText: 'Sí, eliminar',
          cancelButtonText: 'Cancelar',
          customClass: {
            popup: 'swal2-popup-custom'
          }
        }).then((result) => {
          if (result.isConfirmed) {
            form.submit();
          }
        });
      }
    });
  });
});
