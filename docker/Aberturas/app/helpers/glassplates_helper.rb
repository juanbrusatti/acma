module GlassplatesHelper

  # This method format the status of the glassplate for display
  def status_badge_class(status)
    case status
    when 'disponible'
      'border-transparent bg-primary text-primary-foreground hover:bg-primary/80'
    when 'reservado'
      'border-transparent bg-secondary text-secondary-foreground hover:bg-secondary/80'
    when 'usado'
      'border-transparent bg-muted text-muted-foreground'
    else
      'border-transparent bg-muted text-muted-foreground'
    end
  end

  # This method seems to be used for displaying the type of material
  def material_type_label(is_scrap)
    is_scrap ? 'Sobrante/Recorte' : 'Plancha Completa'
  end

  # Calculate stock summary statistics
  def calculate_stock_summary
    {
      total_sheets: Glassplate.complete_sheets.count,
      total_scraps: Glassplate.scraps.count,
      available_scraps: Glassplate.scraps.available.count,
      reserved_scraps: Glassplate.scraps.reserved.count
    }
  end

  # This method formats the measurements of the glassplate
  def format_measures(width, height)
    "#{width.to_i}x#{height.to_i}"
  end

  def format_area(width, height)
    number_with_precision(width * height / 1000000, precision: 2)
  end

  def format_date(date)
    date.strftime("%d/%m/%Y %H:%M")
  end
end
