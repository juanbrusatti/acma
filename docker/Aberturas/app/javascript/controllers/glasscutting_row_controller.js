import { Controller } from "@hotwired/stimulus"

// Manages the inline editing functionality for glasscutting rows
export default class extends Controller {
  static targets = [
    'glassType', 'thickness', 'color', 'height', 'width', 'typology',
    'editBtn', 'saveBtn'
  ]
  
  static values = {
    id: Number,
    updateUrl: String
  }
  
  connect() {
    this.isEditing = false;
    this.setupEventListeners();
  }
  
  setupEventListeners() {
    // Add keyboard event for Enter key
    this.element.addEventListener('keydown', (e) => {
      if (e.key === 'Enter') {
        e.preventDefault();
        this.saveChanges();
      } else if (e.key === 'Escape') {
        e.preventDefault();
        this.cancelEdit();
      }
    });
  }
  
  toggleEdit() {
    if (this.isEditing) return;
    
    this.isEditing = true;
    this.toggleEditMode(true);
    
    // Focus first input
    const firstInput = this.typologyTarget || this.glassTypeTarget;
    if (firstInput) {
      firstInput.focus();
      firstInput.select();
    }
  }
  
  saveChanges() {
    if (!this.isEditing) return;
    
    const data = {
      glasscutting: {
        glass_type: this.glassTypeTarget.value,
        thickness: this.thicknessTarget.value,
        color: this.colorTarget.value,
        height: this.heightTarget.value,
        width: this.widthTarget.value,
        typology: this.typologyTarget?.value || ''
      }
    };
    
    const csrfToken = document.querySelector('meta[name="csrf-token"]').content;
    
    fetch(`/glasscuttings/${this.idValue}`, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': csrfToken,
        'Accept': 'application/json',
        'X-Requested-With': 'XMLHttpRequest'
      },
      body: JSON.stringify(data)
    })
    .then(response => response.json())
    .then(data => {
      if (data.success) {
        this.showFlash('Vidrio actualizado correctamente', 'success');
        this.updateViewValues();
        this.cancelEdit();
      } else {
        this.showFlash('Error al actualizar el vidrio: ' + (data.errors || 'Error desconocido'), 'error');
      }
    })
    .catch(error => {
      console.error('Error:', error);
      this.showFlash('Error de conexión al guardar los cambios', 'error');
    });
  }
  
  cancelEdit() {
    if (!this.isEditing) return;
    
    this.isEditing = false;
    this.toggleEditMode(false);
    this.resetFormValues();
  }
  
  toggleEditMode(editing) {
    // Toggle view/edit elements
    this.element.querySelectorAll('[class$="-view"]').forEach(el => {
      el.style.display = editing ? 'none' : 'inline';
    });
    
    this.element.querySelectorAll('[class$="-edit"]').forEach(el => {
      el.style.display = editing ? 'block' : 'none';
    });
    
    // Toggle buttons
    if (this.hasEditBtnTarget) {
      this.editBtnTarget.style.display = editing ? 'none' : 'inline-flex';
    }
    
    if (this.hasSaveBtnTarget) {
      this.saveBtnTarget.style.display = editing ? 'inline-flex' : 'none';
    }
    
    // Toggle row styling
    if (editing) {
      this.element.classList.add('bg-blue-50');
    } else {
      this.element.classList.remove('bg-blue-50');
    }
  }
  
  updateViewValues() {
    // Update view spans with current input values
    const fields = ['glassType', 'thickness', 'color', 'height', 'width', 'typology'];
    fields.forEach(field => {
      const target = this[`${field}Target`];
      if (target) {
        const viewElement = this.element.querySelector(`.glass-${field.dasherize()}-view`);
        if (viewElement) {
          viewElement.textContent = target.value;
        }
      }
    });
  }
  
  resetFormValues() {
    // Reset inputs to match view values
    const fields = ['glassType', 'thickness', 'color', 'height', 'width', 'typology'];
    fields.forEach(field => {
      const target = this[`${field}Target`];
      if (target) {
        const viewElement = this.element.querySelector(`.glass-${field.dasherize()}-view`);
        if (viewElement) {
          target.value = viewElement.textContent;
        }
      }
    });
  }
  
  showFlash(message, type = 'notice') {
    // You can implement a flash message system here or use an existing one
    const flash = document.createElement('div');
    flash.className = `flash flash-${type} fixed top-4 right-4 px-6 py-3 rounded-md shadow-lg z-50`;
    flash.textContent = message;
    
    document.body.appendChild(flash);
    
    setTimeout(() => {
      flash.remove();
    }, 5000);
  }
}

// Helper to convert camelCase to kebab-case
String.prototype.dasherize = function() {
  return this.replace(/([A-Z])/g, (m, p) => `-${p.toLowerCase()}`);
};
