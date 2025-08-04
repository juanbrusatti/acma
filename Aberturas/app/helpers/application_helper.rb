module ApplicationHelper
  def human_glass_type(type)
    case type.to_s.upcase
    when 'LAM'
      'Laminado'
    when 'FLO'
      'Float'
    when 'COL'
      'Cool Lite'
    else
      type.to_s
    end
  end

  def human_glass_color(color)
    case color.to_s.upcase
    when 'INC'
      'Incoloro'
    when 'GRIS'
      'Gris'
    when 'BRONCE'
      'Bronce'
    when 'ESMERILADO'
      'Esmerilado'
    else
      color.to_s
    end
  end
end
