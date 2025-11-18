// optimize_modal.js
// Módulo para manejar el modal de optimización de cortes

class OptimizeModal {
  constructor() {
    this.modal = null;
    this.openBtn = null;
    this.closeBtn = null;
    this.cancelBtn = null;
    this.form = null;
    this.stockCheckbox = null;
    this.scrapsCheckbox = null;
    this.stockInput = null;
    this.scrapsInput = null;
    this.floLamCheckbox = null;
    this.floLamInput = null;
    this.toggleMultipleBtn = null;
    this.multipleProjectsSection = null;
    this.projectIdsInput = null;
    this.selectedProjectsCount = null;
    this.selectedProjects = new Set();
    this.isMultipleMode = false;
    this.currentProjectId = null;

    this.init();
  }

  init() {
    // Esperar a que el DOM esté listo
    if (document.readyState === 'loading') {
      document.addEventListener('DOMContentLoaded', () => this.setup());
    } else {
      this.setup();
    }

    // También inicializar cuando Turbo cargue una página
    document.addEventListener('turbo:load', () => this.setup());
  }

  setup() {
    // Obtener elementos del DOM
    this.modal = document.getElementById('optimize-modal');
    this.openBtn = document.getElementById('open-optimize-modal');
    this.closeBtn = document.getElementById('close-optimize-modal');
    this.cancelBtn = document.getElementById('cancel-optimize-btn');
    this.form = document.getElementById('optimize-form');
    this.stockCheckbox = document.getElementById('optimize-stock-checkbox');
    this.scrapsCheckbox = document.getElementById('optimize-scraps-checkbox');
    this.stockInput = document.getElementById('optimize-stock-input');
    this.scrapsInput = document.getElementById('optimize-scraps-input');
    this.floLamCheckbox = document.getElementById('flo-lam-checkbox');
    this.floLamInput = document.getElementById('flo-lam-input');
    this.toggleMultipleBtn = document.getElementById('toggle-multiple-projects-btn');
    this.multipleProjectsSection = document.getElementById('multiple-projects-section');
    this.projectIdsInput = document.getElementById('optimize-project-ids-input');
    this.selectedProjectsCount = document.getElementById('selected-projects-count');

    // Verificar que todos los elementos existen
    if (!this.modal || !this.openBtn) {
      console.log('OptimizeModal: Elements not found, skipping setup');
      return;
    }

    // Obtener el ID del proyecto actual desde el modal
    this.currentProjectId = this.modal.getAttribute('data-current-project-id');
    if (this.currentProjectId) {
      this.selectedProjects.add(this.currentProjectId);
    }

    console.log('✅ OptimizeModal initialized');

    // Remover listeners antiguos antes de agregar nuevos (para evitar duplicados)
    this.removeListeners();

    // Configurar event listeners
    this.setupListeners();
  }

  removeListeners() {
    // Clonar y reemplazar elementos para eliminar todos los listeners
    if (this.openBtn) {
      const newOpenBtn = this.openBtn.cloneNode(true);
      this.openBtn.parentNode.replaceChild(newOpenBtn, this.openBtn);
      this.openBtn = newOpenBtn;
    }

    if (this.closeBtn) {
      const newCloseBtn = this.closeBtn.cloneNode(true);
      this.closeBtn.parentNode.replaceChild(newCloseBtn, this.closeBtn);
      this.closeBtn = newCloseBtn;
    }

    if (this.cancelBtn) {
      const newCancelBtn = this.cancelBtn.cloneNode(true);
      this.cancelBtn.parentNode.replaceChild(newCancelBtn, this.cancelBtn);
      this.cancelBtn = newCancelBtn;
    }

    if (this.toggleMultipleBtn) {
      const newToggleBtn = this.toggleMultipleBtn.cloneNode(true);
      this.toggleMultipleBtn.parentNode.replaceChild(newToggleBtn, this.toggleMultipleBtn);
      this.toggleMultipleBtn = newToggleBtn;
    }
  }

  setupListeners() {
    // Abrir modal
    this.openBtn.addEventListener('click', (e) => {
      e.preventDefault();
      this.openModal();
    });

    // Cerrar modal con el botón X
    if (this.closeBtn) {
      this.closeBtn.addEventListener('click', () => {
        this.closeModal();
      });
    }

    // Cerrar modal con el botón Cancelar
    if (this.cancelBtn) {
      this.cancelBtn.addEventListener('click', () => {
        this.closeModal();
      });
    }

    // Cerrar modal al hacer clic fuera de él
    this.modal.addEventListener('click', (e) => {
      if (e.target === this.modal) {
        this.closeModal();
      }
    });

    // Cerrar modal con la tecla Escape
    document.addEventListener('keydown', (e) => {
      if (e.key === 'Escape' && this.isModalOpen()) {
        this.closeModal();
      }
    });

    // Actualizar inputs hidden cuando cambian los checkboxes
    if (this.stockCheckbox && this.stockInput) {
      this.stockCheckbox.addEventListener('change', () => {
        this.stockInput.value = this.stockCheckbox.checked ? 'true' : 'false';
        console.log('Stock checkbox changed:', this.stockCheckbox.checked);
      });
    }

    if (this.scrapsCheckbox && this.scrapsInput) {
      this.scrapsCheckbox.addEventListener('change', () => {
        this.scrapsInput.value = this.scrapsCheckbox.checked ? 'true' : 'false';
        console.log('Scraps checkbox changed:', this.scrapsCheckbox.checked);
      });
    }
    if (this.floLamCheckbox && this.floLamInput) {
      this.floLamCheckbox.addEventListener('change', () => {
        this.floLamInput.value = this.floLamCheckbox.checked ? 'true' : 'false';
        console.log('FLO-LAM checkbox changed:', this.floLamCheckbox.checked);
      });
    }

    // Manejar el submit del formulario
    if (this.form) {
      this.form.addEventListener('submit', (e) => {
        console.log('🚀 Submitting optimization with:', {
          stock: this.stockInput.value,
          scraps: this.scrapsInput.value,
          flo_lam: this.floLamInput.value,
          project_ids: this.projectIdsInput.value
        });
        // El formulario se enviará normalmente, no prevenimos default
      });
    }

    // Toggle para mostrar/ocultar sección de proyectos múltiples
    if (this.toggleMultipleBtn) {
      this.toggleMultipleBtn.addEventListener('click', () => {
        this.toggleMultipleProjectsMode();
      });
    }
  }

  openModal() {
    if (this.modal) {
      this.modal.style.display = 'flex';
      // Resetear checkboxes al abrir
      if (this.stockCheckbox) this.stockCheckbox.checked = false;
      if (this.scrapsCheckbox) this.scrapsCheckbox.checked = false;
      if (this.stockInput) this.stockInput.value = 'false';
      if (this.scrapsInput) this.scrapsInput.value = 'false';
      if (this.floLamCheckbox) this.floLamCheckbox.checked = false;
      if (this.floLamInput) this.floLamInput.value = 'false';

      // Resetear modo múltiple
      this.isMultipleMode = false;
      if (this.multipleProjectsSection) {
        this.multipleProjectsSection.style.display = 'none';
      }
      this.resetProjectSelection();

      // Prevenir scroll del body
      document.body.style.overflow = 'hidden';

      console.log('✅ Modal opened');
    }
  }

  closeModal() {
    if (this.modal) {
      this.modal.style.display = 'none';

      // Restaurar scroll del body
      document.body.style.overflow = '';

      console.log('✅ Modal closed');
    }
  }

  isModalOpen() {
    return this.modal && this.modal.style.display === 'flex';
  }

  toggleMultipleProjectsMode() {
    this.isMultipleMode = !this.isMultipleMode;

    if (this.multipleProjectsSection) {
      this.multipleProjectsSection.style.display = this.isMultipleMode ? 'block' : 'none';
    }

    // Si se desactiva el modo múltiple, resetear selección
    if (!this.isMultipleMode) {
      this.resetProjectSelection();
    } else {
      // Si se activa el modo múltiple, actualizar las piezas convertibles
      this.updateConvertiblePieces();
    }

    console.log('Multiple projects mode:', this.isMultipleMode);
  }

  resetProjectSelection() {
    // Limpiar selección de proyectos
    this.selectedProjects.clear();
    if (this.currentProjectId) {
      this.selectedProjects.add(this.currentProjectId);
    }

    // Deseleccionar todas las tarjetas visualmente
    const projectCards = document.querySelectorAll('.project-card');
    projectCards.forEach(card => {
      card.classList.remove('selected', 'border-blue-600', 'bg-blue-50');
      card.classList.add('border-gray-300');

      const checkbox = card.querySelector('.project-checkbox');
      const checkmark = card.querySelector('.checkmark');
      if (checkbox) {
        checkbox.classList.remove('bg-blue-600', 'border-blue-600');
        checkbox.classList.add('border-gray-400');
      }
      if (checkmark) {
        checkmark.classList.add('hidden');
      }
    });

    // Actualizar input y contador
    this.updateProjectIdsInput();
    this.updateSelectedCount();

    // Actualizar piezas convertibles al proyecto actual solo
    this.updateConvertiblePieces();
  }

  updateProjectIdsInput() {
    if (this.projectIdsInput) {
      // Convertir Set a array y luego a string separado por comas
      const projectIdsArray = Array.from(this.selectedProjects);
      this.projectIdsInput.value = projectIdsArray.join(',');
      console.log('Updated project_ids:', this.projectIdsInput.value);
    }
  }

  updateSelectedCount() {
    if (this.selectedProjectsCount) {
      this.selectedProjectsCount.textContent = this.selectedProjects.size;
    }
  }

  async updateConvertiblePieces() {
    const container = document.getElementById('convertible-pieces-container');
    if (!container) return;

    // Obtener los IDs de proyectos seleccionados
    const projectIds = Array.from(this.selectedProjects).join(',');

    try {
      // Hacer petición al servidor para obtener las piezas convertibles
      const response = await fetch(`/projects/${this.currentProjectId}/convertible_pieces?project_ids=${projectIds}`);

      if (!response.ok) {
        console.error('Error fetching convertible pieces');
        return;
      }

      const data = await response.json();

      // Limpiar el contenedor
      container.innerHTML = '';

      if (data.length === 0) {
        container.innerHTML = '<p class="text-xs text-gray-400">No hay piezas convertibles en los proyectos seleccionados</p>';
        return;
      }

      // Renderizar solo la cantidad de piezas por proyecto
      data.forEach(projectData => {
        const projectBlock = document.createElement('div');
        projectBlock.className = 'p-3 bg-yellow-50 border border-yellow-200 rounded flex-shrink-0 w-auto';
        projectBlock.setAttribute('data-project-id', projectData.project_id);

        projectBlock.innerHTML = `
          <p class="text-sm font-semibold text-yellow-800">
            <span class="text-blue-600">${projectData.project_name}</span>: <span class="text-yellow-900">${projectData.pieces.length} piezas</span>
          </p>
        `;

        container.appendChild(projectBlock);
      });

      console.log('✅ Convertible pieces updated');
    } catch (error) {
      console.error('Error updating convertible pieces:', error);
      container.innerHTML = '<p class="text-xs text-red-400">Error al cargar las piezas convertibles</p>';
    }
  }
}

// Inicializar el modal
const optimizeModal = new OptimizeModal();

// Función global para toggle de selección de proyectos (llamada desde onclick en HTML)
window.toggleProjectSelection = function(cardElement) {
  const projectId = cardElement.getAttribute('data-project-id');

  if (!projectId) {
    console.error('No project ID found');
    return;
  }

  const isSelected = cardElement.classList.contains('selected');
  const checkbox = cardElement.querySelector('.project-checkbox');
  const checkmark = cardElement.querySelector('.checkmark');

  if (isSelected) {
    // Deseleccionar
    cardElement.classList.remove('selected', 'border-blue-600', 'bg-blue-50');
    cardElement.classList.add('border-gray-300');

    if (checkbox) {
      checkbox.classList.remove('bg-blue-600', 'border-blue-600');
      checkbox.classList.add('border-gray-400');
    }
    if (checkmark) {
      checkmark.classList.add('hidden');
    }

    optimizeModal.selectedProjects.delete(projectId);
  } else {
    // Seleccionar
    cardElement.classList.add('selected', 'border-blue-600', 'bg-blue-50');
    cardElement.classList.remove('border-gray-300');

    if (checkbox) {
      checkbox.classList.add('bg-blue-600', 'border-blue-600');
      checkbox.classList.remove('border-gray-400');
    }
    if (checkmark) {
      checkmark.classList.remove('hidden');
    }

    optimizeModal.selectedProjects.add(projectId);
  }

  // Actualizar input hidden y contador
  optimizeModal.updateProjectIdsInput();
  optimizeModal.updateSelectedCount();

  // Actualizar piezas convertibles
  optimizeModal.updateConvertiblePieces();
};

// Exportar para depuración
window.optimizeModal = optimizeModal;

console.log('🎯 optimize_modal.js loaded');
