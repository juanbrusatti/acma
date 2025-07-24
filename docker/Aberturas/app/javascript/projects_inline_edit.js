export function setupProjectEditInline() {
  const editBtn = document.getElementById('edit-btn');
  const confirmBtn = document.getElementById('confirm-btn');
  const cancelBtn = document.getElementById('cancel-btn');
  const actionsView = document.getElementById('project-actions-view');
  const actionsEdit = document.getElementById('project-actions-edit');

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
    if (dateView && dateEdit) {
      dateView.style.display = editing ? 'none' : '';
      dateEdit.style.display = editing ? '' : 'none';
    }
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

  editBtn.onclick = function (e) {
    e.preventDefault();
    toggleEditMode(true);
  };

  cancelBtn.onclick = function (e) {
    e.preventDefault();
    toggleEditMode(false);
  };

  confirmBtn.onclick = function (e) {
    e.preventDefault();
    toggleEditMode(false);

    const data = {
      project: {
        name: nameEdit.value,
        description: descEdit.value,
        status: statusEdit.value,
        delivery_date: dateEdit ? dateEdit.value : null,
        glasscuttings_attributes: []
      }
    };

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
        'Accept': 'application/json', // <-- agregado para asegurar respuesta JSON
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
      },
      body: JSON.stringify(data)
    })
      .then(response => {
        if (!response.ok) throw new Error('Error en la respuesta del servidor');
        return response.json();
      })
      .then(json => {
        if (json.success) {
          const match = window.location.pathname.match(/\/projects\/(\d+)/);
          const projectId = match?.[1] || json.project?.id;
          if (projectId) {
            if (window.Turbo) {
              Turbo.visit(`/projects/${projectId}`, { action: 'replace' });
            } else {
              window.location.href = `/projects/${projectId}`;
            }
          } else {
            window.location.href = '/projects';
          }
        } else {
          alert('Error al guardar: ' + (json.errors ? json.errors.join(', ') : 'Error desconocido'));
        }
      })
      .catch(error => {
        alert('Ocurrió un error al guardar: ' + error.message);
      });
  };
}

document.addEventListener('turbo:load', setupProjectEditInline);
