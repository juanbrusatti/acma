module DashboardHelper
  # generate different styles for project status badges
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

  # format the delivery date to a specific string format
  def format_delivery_date(date)
    date.strftime("%Y-%m-%d")
  end

  # generate the text for stock summary and scraps available
  def stock_summary_text(total_sheets, available_scraps)
    "#{total_sheets} Planchas"
  end

  def stock_scraps_text(available_scraps)
    "+#{available_scraps} sobrantes disponibles"
  end
end
