import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="client-info"
export default class extends Controller {
  static targets = ["editButton", "fields"]
  static values = {
    url: String,
    projectId: String,
    editing: { type: Boolean, default: false }
  }

  connect() {
    // Inicialmente no estamos editando
    this.isEditing = false;
    
    // Si hay un projectId, asegurarse de que el botón de editar sea visible
    if (this.hasProjectIdValue && this.projectIdValue) {
      this.element.style.display = 'block';
    } else {
      // Si es un proyecto nuevo, ocultar el botón de editar
      if (this.hasEditButtonTarget) {
        this.editButtonTarget.style.display = 'none';
      }
    }
    
    this.originalButtonText = 'Editar';
    this.updateUI();
  }

  async toggleEdit(event) {
    event.preventDefault();
    this.isEditing = !this.isEditing;
    this.updateUI();
    
    // Si estamos guardando, enviar los cambios
    if (!this.isEditing) {
      this.saveChanges();
    } else {
      // Si estamos entrando en modo edición, guardar el texto original del botón
      this.originalButtonText = 'Editar';
      if (firstInput) {
        firstInput.focus();
      }
    }
  }

  async saveChanges() {
    const form = this.element.closest('form');
    const formData = new FormData(form);
    const csrfToken = document.querySelector('meta[name="csrf-token"]').content;
    
    // Deshabilitar el botón mientras se guarda
    const button = this.editButtonTarget;
    const originalButtonText = button.textContent;
    button.disabled = true;
    button.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Guardando...';
    
    try {
      // Usar fetch para hacer la petición PATCH
      const response = await fetch(this.urlValue, {
        method: 'PATCH',
        headers: {
          'X-CSRF-Token': csrfToken,
          'Accept': 'application/json',
          'X-Requested-With': 'XMLHttpRequest'
        },
        body: formData
      });
      
      const data = await response.json();
      
      if (response.ok) {
        // Si la respuesta es exitosa, salir del modo edición
        this.isEditing = false;
        this.updateUI();
        
        // Mostrar mensaje de éxito
        this.showFlash(data.notice || 'Los cambios se guardaron correctamente', 'success');
      } else {
        // Mostrar mensaje de error
        const errorMessage = data.errors ? data.errors.join(', ') : 'Error al guardar los cambios';
        this.showFlash(errorMessage, 'error');
      }
    } catch (error) {
      console.error('Error al guardar los cambios:', error);
      this.showFlash('Error de conexión al guardar los cambios', 'error');
    } finally {
      // Restaurar el botón
      button.disabled = false;
      button.textContent = originalButtonText;
    }
  }

  updateUI() {
    const inputs = this.fieldsTarget?.querySelectorAll('input, textarea, select') || [];
    
    if (this.isEditing) {
      // Modo edición
      if (this.hasEditButtonTarget) {
        this.editButtonTarget.textContent = 'Guardar';
        this.editButtonTarget.classList.remove('bg-blue-500', 'hover:bg-blue-600');
        this.editButtonTarget.classList.add('bg-green-500', 'hover:bg-green-600');
      }
      
      inputs.forEach(input => {
        input.readOnly = false;
        input.classList.remove('bg-gray-100', 'cursor-not-allowed');
      });
    } else {
      // Modo solo lectura - solo aplica si ya existe un proyecto
      if (this.hasProjectIdValue && this.projectIdValue) {
        if (this.hasEditButtonTarget) {
          this.editButtonTarget.textContent = 'Editar';
          this.editButtonTarget.classList.remove('bg-green-500', 'hover:bg-green-600');
          this.editButtonTarget.classList.add('bg-blue-500', 'hover:bg-blue-600');
        }
        
        inputs.forEach(input => {
          input.readOnly = true;
          input.classList.add('bg-gray-100', 'cursor-not-allowed');
        });
      } else {
        // Si no hay project_id, los campos deben ser editables por defecto
        // y el botón de editar debe estar oculto
        inputs.forEach(input => {
          input.readOnly = false;
          input.classList.remove('bg-gray-100', 'cursor-not-allowed');
        });
        
        if (this.hasEditButtonTarget) {
          this.editButtonTarget.style.display = 'none';
        }
      }
    }
  }
  
  showFlash(message, type = 'notice') {
    // Eliminar mensajes flash existentes
    const existingFlash = document.querySelector('.flash-message');
    if (existingFlash) {
      existingFlash.remove();
    }
    
    // Crear y mostrar el nuevo mensaje flash
    const flash = document.createElement('div');
    flash.className = `flash-message fixed top-4 right-4 px-6 py-3 rounded-md shadow-lg ${
      type === 'error' ? 'bg-red-100 border-l-4 border-red-500 text-red-700' : 
      'bg-green-100 border-l-4 border-green-500 text-green-700'
    }`;
    flash.textContent = message;
    document.body.appendChild(flash);
    
    // Eliminar el mensaje después de 5 segundos
    setTimeout(() => {
      flash.remove();
    }, 5000);
  }
}
