// Edición inline para proyectos y vidrios
export function setupProjectEditInline() {
  const editBtn = document.getElementById('edit-btn');
  const confirmBtn = document.getElementById('confirm-btn');
  const cancelBtn = document.getElementById('cancel-btn');
  const actionsView = document.getElementById('project-actions-view');
  const actionsEdit = document.getElementById('project-actions-edit');

  // Campos generales
  const nameView = document.getElementById('project-name-view');
  const nameEdit = document.getElementById('project-name-edit');
  const descView = document.getElementById('project-desc-view');
  const descEdit = document.getElementById('project-desc-edit');
  const statusView = document.getElementById('project-status-view');
  const statusEdit = document.getElementById('project-status-edit');
  const dateView = document.getElementById('project-date-view');
  const dateEdit = document.getElementById('project-date-edit');

  if (!editBtn || !confirmBtn || !cancelBtn) return;

  function toggleEditMode(editing) {
    nameView.style.display = editing ? 'none' : '';
    nameEdit.style.display = editing ? '' : 'none';
    descView.style.display = editing ? 'none' : '';
    descEdit.style.display = editing ? '' : 'none';
    statusView.style.display = editing ? 'none' : '';
    statusEdit.style.display = editing ? '' : 'none';
    if(dateView && dateEdit) {
      dateView.style.display = editing ? 'none' : '';
      dateEdit.style.display = editing ? '' : 'none';
    }
    // Glasscuttings
    document.querySelectorAll('.glass-type-view').forEach(e => e.style.display = editing ? 'none' : '');
    document.querySelectorAll('.glass-type-edit').forEach(e => e.style.display = editing ? '' : 'none');
    document.querySelectorAll('.glass-thickness-view').forEach(e => e.style.display = editing ? 'none' : '');
    document.querySelectorAll('.glass-thickness-edit').forEach(e => e.style.display = editing ? '' : 'none');
    document.querySelectorAll('.glass-color-view').forEach(e => e.style.display = editing ? 'none' : '');
    document.querySelectorAll('.glass-color-edit').forEach(e => e.style.display = editing ? '' : 'none');
    document.querySelectorAll('.glass-location-view').forEach(e => e.style.display = editing ? 'none' : '');
    document.querySelectorAll('.glass-location-edit').forEach(e => e.style.display = editing ? '' : 'none');
    document.querySelectorAll('.glass-height-view').forEach(e => e.style.display = editing ? 'none' : '');
    document.querySelectorAll('.glass-height-edit').forEach(e => e.style.display = editing ? '' : 'none');
    document.querySelectorAll('.glass-width-view').forEach(e => e.style.display = editing ? 'none' : '');
    document.querySelectorAll('.glass-width-edit').forEach(e => e.style.display = editing ? '' : 'none');
    actionsView.style.display = editing ? 'none' : '';
    actionsEdit.style.display = editing ? '' : 'none';
  }

  editBtn.onclick = function(e) {
    e.preventDefault();
    toggleEditMode(true);
  };

  cancelBtn.onclick = function(e) {
    e.preventDefault();
    toggleEditMode(false);
  };

  confirmBtn.onclick = function(e) {
    e.preventDefault();
    // Construir datos generales
    const data = {
      project: {
        name: nameEdit.value,
        description: descEdit.value,
        status: statusEdit.value,
        delivery_date: dateEdit ? dateEdit.value : null,
        glasscuttings_attributes: []
      }
    };
    // Recolectar datos de los vidrios
    const rows = document.querySelectorAll('#glasscuttings-table-body tr');
    rows.forEach((row) => {
      data.project.glasscuttings_attributes.push({
        id: row.querySelector('.glass-type-edit').getAttribute('data-id'),
        glass_type: row.querySelector('.glass-type-edit').value,
        thickness: row.querySelector('.glass-thickness-edit').value,
        color: row.querySelector('.glass-color-edit').value,
        location: row.querySelector('.glass-location-edit').value,
        height: row.querySelector('.glass-height-edit').value,
        width: row.querySelector('.glass-width-edit').value
      });
    });
    fetch(window.location.pathname, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
      },
      body: JSON.stringify(data)
    })
    .then(response => response.json())
    .then(json => {
      if(json.success) {
        window.location.reload();
      } else {
        alert('Error al guardar: ' + (json.errors ? json.errors.join(', ') : 'Error desconocido'));
      }
    });
  };
}

document.addEventListener('DOMContentLoaded', setupProjectEditInline);
document.addEventListener('turbo:load', setupProjectEditInline); 