module DashboardHelper
  # generate different styles for project status badges
  def project_status_badge_class(status)
    case status
    when "Terminado"
      "border-transparent bg-secondary text-secondary-foreground hover:bg-secondary/80"
    when "En Proceso"
      "border-transparent bg-warning text-warning-foreground hover:bg-warning/80"
    else
      "border-transparent bg-muted text-muted-foreground hover:bg-muted/80"
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

  def projects_summary_text(active_projects)
    "#{active_projects} Proyectos"
  end

  def projects_completed_text(completed_this_month)
    "#{completed_this_month} proyectos finalizados este mes"
  end
end
