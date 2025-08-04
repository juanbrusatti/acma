document.addEventListener('DOMContentLoaded', function() {
  console.log('preview_pdf.js cargado');
  const pdfBtn = document.getElementById('preview-pdf-btn');
  if (!pdfBtn) return;

  pdfBtn.addEventListener('click', function(e) {
    e.preventDefault();
    const form = pdfBtn.closest('form');
    if (!form) return;

    const formData = new FormData(form);
    const csrfToken = document.querySelector('meta[name="csrf-token"]').getAttribute('content');
    fetch('/projects/preview_pdf', {
      method: 'POST',
      body: formData,
      headers: {
        'Accept': 'application/pdf',
        'X-CSRF-Token': csrfToken
      }
    })
    .then(async response => {
      if (!response.ok) {
        const text = await response.text();
        throw new Error(text);
      }
      return response.blob();
    })
    .then(blob => {
      const url = window.URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = 'proyecto_preview.pdf';
      document.body.appendChild(a);
      a.click();
      a.remove();
      window.URL.revokeObjectURL(url);
    })
    .catch(err => {
      alert('Error: ' + err.message);
    });
  });
});
