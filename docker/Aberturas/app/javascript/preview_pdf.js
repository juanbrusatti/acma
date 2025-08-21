// PDF Button Initialization and Management
// This module handles PDF generation for project preview functionality
// It manages event listeners for Turbo navigation and ensures proper initialization

// Function to initialize the PDF button with event listeners
function initializePdfButton() {
  console.log('Inicializando botón PDF...');
  
  const pdfBtn = document.getElementById('preview-pdf-btn');

  // Early return if PDF button doesn't exist in DOM
  if (!pdfBtn) {
    console.warn('Botón PDF no encontrado');
    return;
  }

  
  // Prevent duplicate initialization by checking data attribute
  if (pdfBtn.hasAttribute('data-pdf-initialized')) {
    console.log('Botón PDF ya inicializado');
    return;
  }
  
  console.log('Agregando event listener al botón PDF...');
  
  // Mark button as initialized to prevent duplicate listeners
  pdfBtn.setAttribute('data-pdf-initialized', 'true');
  
  // Add click event listener for PDF generation
  pdfBtn.addEventListener('click', function(e) {
    console.log('=== PDF Button Clicked ===');
    e.preventDefault();

    // Validar si hay vidrios por confirmar o cancelar
    const openGlasscuttingForms = document.querySelectorAll('.glasscutting-fields:not(.hidden) input:not([disabled])');
    const openDvhForms = document.querySelectorAll('.dvh-fields:not(.hidden) input:not([disabled])');
    if (openGlasscuttingForms.length > 0 || openDvhForms.length > 0) {
      const swalConfig = window.getSwalConfig ? window.getSwalConfig() : {};
      window.Swal.fire({
        ...swalConfig,
        title: 'Faltan vidrios por confirmar o cancelar',
      });
      return;
    }

    // Find the parent form containing project data
    const form = pdfBtn.closest('form');

    if (!form) {
      console.error('Formulario no encontrado');
      alert('Error: No se encontró el formulario');
      return;
    }

    // Create FormData object with all form inputs
    const formData = new FormData(form);
    formData.delete('_method');
    const csrfToken = document.querySelector('meta[name="csrf-token"]');

    // Validate CSRF token exists for security
    if (!csrfToken) {
      console.error('CSRF token no encontrado');
      alert('Error: No se encontró el token CSRF');
      return;
    }

    const tokenValue = csrfToken.getAttribute('content');
    console.log('Enviando request PDF...');

    // Update button state to show loading
    pdfBtn.disabled = true;
    pdfBtn.textContent = 'Generando PDF...';

    // Send POST request to backend for PDF generation
    fetch('/projects/preview_pdf', {
      method: 'POST',
      body: formData,
      headers: {
        'Accept': 'application/pdf',
        'X-CSRF-Token': tokenValue
      }
    })
    .then(async response => {
      console.log('Response:', response.status, response.statusText);

      // Handle non-successful responses
      if (!response.ok) {
        const text = await response.text();
        console.error('Error response:', text);
        throw new Error(`Error ${response.status}: ${text}`);
      }

      // Convert response to blob for file download
      return response.blob();
    })
    .then(blob => {
      console.log('PDF recibido:', blob.size, 'bytes');

      // Validate PDF blob is not empty
      if (blob.size === 0) {
        throw new Error('El PDF está vacío');
      }

      // Generate filename based on project name
      const projectNameInput = form.querySelector('input[name="project[name]"]');
      let fileName = 'Proyecto';

      if (projectNameInput && projectNameInput.value.trim()) {
        // Clean project name for safe filename usage
        const projectName = projectNameInput.value.trim()
          .replace(/[^a-zA-Z0-9\s\-_]/g, '') // Remove special characters
          .replace(/\s+/g, '_') // Replace spaces with underscores
          .substring(0, 50); // Limit length to avoid filesystem issues
        fileName = `Proyecto_${projectName}`;
      }

      // Create and trigger download link
      const url = window.URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = `${fileName}.pdf`;
      document.body.appendChild(a);
      a.click();
      a.remove();
      window.URL.revokeObjectURL(url); // Clean up memory

      console.log(`Descarga PDF completada: ${fileName}.pdf`);
    })
    .catch(err => {
      console.error('Error generando PDF:', err);
      alert('Error generando PDF: ' + err.message);
    })
    .finally(() => {
      // Restore button to original state regardless of success/failure
      pdfBtn.disabled = false;
      pdfBtn.textContent = 'Guardar PDF';
    });
  });
  
  console.log('Event listener PDF agregado exitosamente');
}

// Function to clean up button initialization before page cache
function cleanupPdfButton() {
  const pdfBtn = document.getElementById('preview-pdf-btn');
  if (pdfBtn) {
    // Remove initialization flag to allow re-initialization
    pdfBtn.removeAttribute('data-pdf-initialized');
  }
}

// Event listeners for different page load scenarios
// Handle initial page load (traditional navigation)
document.addEventListener('DOMContentLoaded', function() {
  console.log('DOMContentLoaded - inicializando PDF');
  setTimeout(initializePdfButton, 100);
});

// Handle Turbo navigation (SPA-like page transitions)
document.addEventListener('turbo:load', function() {
  console.log('Turbo:load - inicializando PDF');
  setTimeout(initializePdfButton, 100);
});

// Clean up before Turbo caches the page to prevent memory leaks
document.addEventListener('turbo:before-cache', function() {
  console.log('Turbo:before-cache - limpiando PDF');
  cleanupPdfButton();
});

// Fallback initialization when window fully loads (safety net)
window.addEventListener('load', function() {
  console.log('Window load - verificando PDF');
  setTimeout(initializePdfButton, 200);
});
