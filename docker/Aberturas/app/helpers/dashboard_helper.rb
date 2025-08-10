module DashboardHelper
  # === OPTIMIZED STATUS BADGE METHODS ===
  
  # Cached status badge classes for better performance
  STATUS_BADGE_CLASSES = {
    'Terminado' => 'bg-green-100 text-green-700 border-green-200',
    'En Proceso' => 'bg-blue-100 text-blue-700 border-blue-200',
    'Pendiente' => 'bg-yellow-100 text-yellow-700 border-yellow-200',
    'Cancelado' => 'bg-red-100 text-red-700 border-red-200'
  }.freeze

  def project_status_badge_class(status)
    STATUS_BADGE_CLASSES[status] || 'bg-gray-100 text-gray-500 border-gray-200'
  end

  # === DATE FORMATTING METHODS ===
  
  def format_delivery_date(date)
    return 'Sin fecha' unless date
    date.strftime('%d-%m-%Y')
  end

  def format_relative_date(date)
    return 'Sin fecha' unless date
    time_ago_in_words(date) + ' ago'
  end

  # === STOCK SUMMARY METHODS ===
  
  def stock_summary_text(total_sheets, available_scraps)
    "#{pluralize(total_sheets, 'Plancha')}"
  end

  def stock_scraps_text(available_scraps)
    return 'Sin sobrantes' if available_scraps.zero?
    "+#{pluralize(available_scraps, 'sobrante')} disponibles"
  end

  # === PROJECT SUMMARY METHODS ===
  
  def projects_summary_text(active_projects)
    return 'Sin proyectos activos' if active_projects.zero?
    "#{pluralize(active_projects, 'proyecto')} activo#{'s' if active_projects > 1}"
  end

  def projects_completed_text(completed_this_month)
    return 'Ninguno completado este mes' if completed_this_month.zero?
    "#{pluralize(completed_this_month, 'completado')} este mes"
  end

  # === DASHBOARD CARD CLASSES ===
  
  def dashboard_card_classes
    'glass-card rounded-3xl border border-gray-200 bg-card shadow-[0_8px_32px_0_rgba(0,0,0,0.15)] text-card-foreground transition-all duration-500 ease-out hover:shadow-[0_20px_48px_rgba(0,0,0,0.25)] hover:-translate-y-0.5'
  end

  def modern_button_classes
    'modern-button inline-flex items-center justify-center gap-2 whitespace-nowrap rounded-md text-sm font-medium transition-all duration-300 h-9 px-3 ripple-effect'
  end

  # === PERFORMANCE OPTIMIZATION METHODS ===
  
  def cached_dashboard_data
    Rails.cache.fetch('dashboard_summary', expires_in: 5.minutes) do
      {
        stock_data: calculate_stock_data,
        projects_data: calculate_projects_data,
        recent_projects: fetch_recent_projects
      }
    end
  end

  private

  def calculate_stock_data
    {
      total_sheets: Glassplate.where(is_scrap: false).count,
      available_scraps: Glassplate.where(is_scrap: true).count
    }
  end

  def calculate_projects_data
    {
      active_projects: Project.where(status: 'En Proceso').count,
      completed_this_month: Project.where(
        status: 'Terminado',
        updated_at: Time.current.beginning_of_month..Time.current.end_of_month
      ).count
    }
  end

  def fetch_recent_projects
    Project.includes(:client)
           .order(created_at: :desc)
           .limit(5)
  end
end
