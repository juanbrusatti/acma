document.addEventListener('DOMContentLoaded', function() {
  console.log('Preview PDF JS loaded');
  
  // Wait for DOM to be fully ready
  setTimeout(() => {
    const pdfBtn = document.getElementById('preview-pdf-btn');
    
    if (pdfBtn) {
      console.log('PDF button found, adding click listener...');
      
      // Remove any existing listeners by cloning the button
      const newBtn = pdfBtn.cloneNode(true);
      pdfBtn.parentNode.replaceChild(newBtn, pdfBtn);
      
      newBtn.addEventListener('click', function(e) {
        console.log('PDF button clicked');
        e.preventDefault();
        
        const form = newBtn.closest('form');
        
        if (!form) {
          console.error('Form not found');
          alert('Error: No se encontró el formulario');
          return;
        }

        const formData = new FormData(form);
        const csrfToken = document.querySelector('meta[name="csrf-token"]');
        
        if (!csrfToken) {
          alert('Error: No se encontró el token CSRF');
          return;
        }
        
        const tokenValue = csrfToken.getAttribute('content');
        console.log('Sending PDF request...');
        
        // Show loading state
        newBtn.disabled = true;
        newBtn.textContent = 'Generando PDF...';
        
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
          
          if (!response.ok) {
            const text = await response.text();
            console.error('Error response:', text);
            throw new Error(`Error ${response.status}: ${text}`);
          }
          
          return response.blob();
        })
        .then(blob => {
          console.log('PDF received:', blob.size, 'bytes');
          
          if (blob.size === 0) {
            throw new Error('El PDF está vacío');
          }
          
          // Download the PDF
          const url = window.URL.createObjectURL(blob);
          const a = document.createElement('a');
          a.href = url;
          a.download = 'proyecto_preview.pdf';
          document.body.appendChild(a);
          a.click();
          a.remove();
          window.URL.revokeObjectURL(url);
          
          console.log('PDF download completed');
        })
        .catch(err => {
          console.error('PDF generation error:', err);
          alert('Error generando PDF: ' + err.message);
        })
        .finally(() => {
          // Restore button state
          newBtn.disabled = false;
          newBtn.textContent = 'Guardar PDF';
        });
      });
      
      console.log('PDF click listener added successfully');
    } else {
      console.warn('PDF button not found');
    }
  }, 1000);
});

// Also handle Turbo page loads
document.addEventListener('turbo:load', function() {
  console.log('Turbo load - checking for PDF button...');
  setTimeout(() => {
    const pdfBtn = document.getElementById('preview-pdf-btn');
    if (pdfBtn && !pdfBtn.hasAttribute('data-pdf-ready')) {
      pdfBtn.setAttribute('data-pdf-ready', 'true');
      console.log('PDF button found on turbo:load');
    }
  }, 500);
});
