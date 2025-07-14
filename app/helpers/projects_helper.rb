  def project_status_badge_class(status)
    case status
    when 'Terminado'
      'bg-green-100 text-green-700'
    when 'En Proceso'
      'bg-blue-100 text-blue-700'
    when 'Pendiente'
      'bg-yellow-100 text-yellow-700'
    else
      'bg-gray-100 text-gray-500'
    end
  end

  def project_status_color(status)
    case status
    when 'Terminado'
      'text-green-600'
    when 'En Proceso'
      'text-blue-600'
    when 'Pendiente'
      'text-yellow-600'
    else
      'text-gray-600'
    end
  end 