// Supply inline editing functionality
// Functions to handle editing supply prices in the table

export function startEdit(supplyId) {
  // Hide price display and edit button
  const priceDisplay = document.getElementById('price_display_' + supplyId);
  const editBtn = document.getElementById('edit_btn_' + supplyId);
  const editForm = document.getElementById('edit_form_' + supplyId);
  
  if (priceDisplay) priceDisplay.style.display = 'none';
  if (editBtn) editBtn.style.display = 'none';
  
  // Show edit form
  if (editForm) {
    editForm.classList.remove('hidden');
    editForm.classList.add('flex');
  }
  
  // Focus on input field
  const input = document.querySelector('#edit_form_' + supplyId + ' input[type="number"]');
  if (input) {
    input.focus();
    input.select();
  }
}

export function cancelEdit(supplyId) {
  // Show price display and edit button
  const priceDisplay = document.getElementById('price_display_' + supplyId);
  const editBtn = document.getElementById('edit_btn_' + supplyId);
  const editForm = document.getElementById('edit_form_' + supplyId);
  
  if (priceDisplay) priceDisplay.style.display = 'inline';
  if (editBtn) editBtn.style.display = 'inline-flex';
  
  // Hide edit form
  if (editForm) {
    editForm.classList.add('hidden');
    editForm.classList.remove('flex');
  }
}

// Make functions globally available for onclick handlers
window.startEdit = startEdit;
window.cancelEdit = cancelEdit;
