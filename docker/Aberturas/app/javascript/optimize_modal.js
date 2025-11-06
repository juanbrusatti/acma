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

    // Verificar que todos los elementos existen
    if (!this.modal || !this.openBtn) {
      console.log('OptimizeModal: Elements not found, skipping setup');
      return;
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
          scraps: this.scrapsInput.value
        });
        // El formulario se enviará normalmente, no prevenimos default
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
}

// Inicializar el modal
const optimizeModal = new OptimizeModal();

// Exportar para depuración
window.optimizeModal = optimizeModal;

console.log('🎯 optimize_modal.js loaded');
