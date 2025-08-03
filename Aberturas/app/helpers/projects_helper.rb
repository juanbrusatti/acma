module ProjectsHelper
  def project_status_color(status)
    case status
    when "Terminado"
      "text-green-600"
    when "En Proceso"
      "text-blue-600"
    when "Pendiente"
      "text-yellow-600"
    else
      "text-gray-600"
    end
  end

  def project_status_icon(status)
    case status
    when "Terminado"
      "M22 11.08V12a10 10 0 1 1-5.93-9.14 M22,4 12,14.01 9,11.01"
    when "En Proceso"
      "M12 2v4 M12 18v4 M4.93 4.93l2.83 2.83 M16.24 16.24l2.83 2.83 M2 12h4 M18 12h4 M4.93 19.07l2.83-2.83 M16.24 7.76l2.83-2.83"
    when "Pendiente"
      "M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"
    else
      "M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
    end
  end

  def projects_summary_text(count)
    "#{count} #{'proyecto'.pluralize(count)}"
  end

  def projects_completed_text(count)
    "#{count} completado#{'s' if count != 1} este mes"
  end

  def project_delivery_status(project)
    return "Sin fecha" unless project.delivery_date.present?

    if project.overdue?
      "Atrasado"
    elsif project.days_until_delivery&.positive?
      "En #{project.days_until_delivery} días"
    elsif project.days_until_delivery&.zero?
      "Hoy"
    else
      "Completado"
    end
  end

  def project_delivery_color(project)
    return "text-gray-500" unless project.delivery_date.present?

    if project.overdue?
      "text-red-600"
    elsif project.days_until_delivery&.positive?
      "text-blue-600"
    elsif project.days_until_delivery&.zero?
      "text-orange-600"
    else
      "text-green-600"
    end
  end

  # Serialize project data for JSON responses
  def project_json_data(project)
    project.as_json(
      only: [:id, :name, :description, :status, :delivery_date], 
      include: { 
        glasscuttings: { only: [:id, :glass_type, :thickness, :color, :typology, :height, :width] } 
      }
    )
  end

  # Generate status badge HTML for AJAX responses
  def project_status_badge_html(status)
    render_to_string(
      partial: "projects/partials/status_badge", 
      locals: { status: status }, 
      formats: [:html]
    )
  end
end
