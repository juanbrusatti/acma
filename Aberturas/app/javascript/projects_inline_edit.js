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
  const statusSelector = document.getElementById('status-selector');
  const statusSelectorDirect = document.getElementById('status-selector-direct');
  const dateView = document.getElementById('project-date-view');
  const dateEdit = document.getElementById('project-date-edit');

  // Configurar el selector de estado directo
  if (statusSelectorDirect) {
    statusSelectorDirect.addEventListener('change', function(e) {
      const newStatus = e.target.value;
      const projectId = e.target.getAttribute('data-project-id');
      const originalValue = e.target.getAttribute('data-original-value') || e.target.value;
      
      // Guardar el valor original para poder restaurarlo en caso de error
      if (!e.target.getAttribute('data-original-value')) {
        e.target.setAttribute('data-original-value', originalValue);
      }
      
      // Deshabilitar el select temporalmente
      e.target.disabled = true;
      e.target.style.opacity = '0.6';
      
      // Enviar petición para actualizar el estado
      fetch(`/projects/${projectId}`, {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
        },
        body: JSON.stringify({
          project: {
            status: newStatus
          }
        })
      })
      .then(response => {
        if (!response.ok) throw new Error('Error en la respuesta del servidor');
        return response.json();
      })
      .then(json => {
        if (json.success) {
          // Actualizar las clases CSS del select según el nuevo estado
          const badgeClass = getBadgeClassForStatus(newStatus);
          e.target.className = `inline-block rounded-full px-3 py-1 text-xs font-semibold ${badgeClass} shadow-sm border border-transparent whitespace-nowrap focus:outline-none focus:ring-2 focus:ring-blue-500 cursor-pointer`;
          
          // Actualizar el valor original
          e.target.setAttribute('data-original-value', newStatus);
        } else {
          throw new Error('Error al actualizar el estado');
        }
      })
      .catch(error => {
        // Restaurar el valor original en caso de error
        e.target.value = e.target.getAttribute('data-original-value');
        alert('Error al actualizar el estado: ' + error.message);
      })
      .finally(() => {
        // Rehabilitar el select
        e.target.disabled = false;
        e.target.style.opacity = '1';
      });
    });
  }
  
  // Función auxiliar para obtener las clases CSS según el estado
  function getBadgeClassForStatus(status) {
    switch(status) {
      case 'Terminado':
        return 'bg-green-100 text-green-700';
      case 'En Proceso':
        return 'bg-blue-100 text-blue-700';
      case 'Pendiente':
        return 'bg-yellow-100 text-yellow-700';
      default:
        return 'bg-gray-100 text-gray-500';
    }
  }

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
        status: statusSelector ? statusSelector.value : statusEdit.value,
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
