module PdfHelper
  # Configuración común para PDFs
  def pdf_common_options
    {
      layout: "pdf",
      enable_local_file_access: true,
      margin: { top: 10, bottom: 10, left: 10, right: 10 },
      disable_smart_shrinking: true,
      page_size: 'A4',
      print_media_type: true,
      disable_external_links: true,
      disable_forms: true
    }
  end

  # Configuración específica para PDF principal
  def pdf_main_options
    pdf_common_options.merge(
      javascript_delay: 300,
      timeout: 30
    )
  end

  # Configuración específica para PDF preview
  def pdf_preview_options
    pdf_common_options.merge(
      javascript_delay: 200,
      timeout: 15
    )
  end

  # Estilos comunes para tablas
  def table_styles
    {
      table: "width:100%; border-collapse: separate; border-spacing: 0; margin-bottom: 20px; font-size: 14px; border-radius: 8px; overflow: hidden; box-shadow: 0 2px 8px #eee;",
      header: "background: #f3f3f3; color: #222; font-weight: bold;",
      header_cell: "padding: 8px; border-bottom: 2px solid #ddd; text-align: center;",
      row_even: "#fff",
      row_odd: "#f9f9f9",
      cell: "padding: 8px; border-bottom: 1px solid #eee; text-align: center;",
      footer_total: "text-align:right; padding: 8px; font-weight: bold; background: #f3f3f3; border-top: 2px solid #ddd;",
      footer_total_cell: "padding: 8px; font-weight: bold; background: #f3f3f3; border-top: 2px solid #ddd; text-align: right;",
      footer_iva: "text-align:right; padding: 8px; font-weight: bold; background: #e0e0e0;",
      footer_iva_cell: "padding: 8px; font-weight: bold; background: #e0e0e0; text-align: right;"
    }
  end

  # Calcula el total con IVA para DVH
  def calculate_dvh_total_with_iva(dvhs)
    return 0 if dvhs.blank?
    
    total = dvhs.sum do |dvh|
      dvh.respond_to?(:price) && dvh.price.present? ? dvh.price.to_f : 0
    end
    total * 1.21
  end

  # Calcula el total con IVA para vidrios simples
  def calculate_glasscuttings_total_with_iva(glasscuttings)
    return 0 if glasscuttings.blank?
    
    total = glasscuttings.sum { |glass| glass.price.to_f }
    total * 1.21
  end

  # Calcula el total sin IVA para DVH
  def calculate_dvh_total(dvhs)
    return 0 if dvhs.blank?
    
    dvhs.sum do |dvh|
      dvh.respond_to?(:price) && dvh.price.present? ? dvh.price.to_f : 0
    end
  end

  # Calcula el total sin IVA para vidrios simples
  def calculate_glasscuttings_total(glasscuttings)
    return 0 if glasscuttings.blank?
    
    glasscuttings.sum { |glass| glass.price.to_f }
  end

  # Renderiza una tabla de DVH
  def render_dvh_table(dvhs)
    return render_empty_message("No se han agregado DVH a este proyecto.") if dvhs.blank?

    styles = table_styles
    dvh_total = calculate_dvh_total(dvhs)
    
    content_tag :table, border: "0", cellspacing: "0", cellpadding: "0", style: styles[:table] do
      concat(render_dvh_header(styles))
      concat(render_dvh_body(dvhs, styles))
      concat(render_dvh_footer(dvh_total, styles))
    end
  end

  # Renderiza una tabla de vidrios simples
  def render_glasscuttings_table(glasscuttings)
    return render_empty_message("No se han agregado vidrios simples a este proyecto.") if glasscuttings.blank?

    styles = table_styles
    glasscuttings_total = calculate_glasscuttings_total(glasscuttings)
    
    content_tag :table, border: "0", cellspacing: "0", cellpadding: "0", style: styles[:table] do
      concat(render_glasscuttings_header(styles))
      concat(render_glasscuttings_body(glasscuttings, styles))
      concat(render_glasscuttings_footer(glasscuttings_total, styles))
    end
  end

  private

  def render_empty_message(message)
    content_tag :p, message, 
      style: "padding: 20px; text-align: center; color: #666; font-style: italic; border: 1px solid #ddd; border-radius: 8px; background: #f9f9f9;"
  end

  def render_dvh_header(styles)
    content_tag :thead do
      content_tag :tr, style: styles[:header] do
        %w[Tipologia Cristal\ 1 Cristal\ 2 Camara Alto Ancho Precio].map do |header|
          content_tag :th, header, style: styles[:header_cell]
        end.join.html_safe
      end
    end
  end

  def render_dvh_body(dvhs, styles)
    content_tag :tbody do
      dvhs.each_with_index.map do |dvh, idx|
        precio = dvh.respond_to?(:price) && dvh.price.present? ? dvh.price.to_f : 0
        
        content_tag :tr, style: "background: #{idx.even? ? styles[:row_even] : styles[:row_odd]};" do
          [
            dvh.typology.present? ? dvh.typology : '-',
            [dvh.glasscutting1_type, dvh.glasscutting1_thickness, dvh.glasscutting1_color].compact.join(' / ').presence || '-',
            [dvh.glasscutting2_type, dvh.glasscutting2_thickness, dvh.glasscutting2_color].compact.join(' / ').presence || '-',
            dvh.innertube.present? ? dvh.innertube : '-',
            dvh.height.present? ? dvh.height : '-',
            dvh.width.present? ? dvh.width : '-',
            precio > 0 ? number_to_currency(precio, unit: "$", precision: 2) : '-'
          ].map do |cell_content|
            content_tag :td, cell_content, style: styles[:cell]
          end.join.html_safe
        end
      end.join.html_safe
    end
  end

  def render_dvh_footer(total, styles)
    total_con_iva = total * 1.21
    
    content_tag :tfoot do
      [
        content_tag(:tr) do
          content_tag(:td, "Total sin IVA:", colspan: "6", style: styles[:footer_total]) +
          content_tag(:td, number_to_currency(total, unit: "$", precision: 2), style: styles[:footer_total_cell])
        end,
        content_tag(:tr) do
          content_tag(:td, "Total con IVA:", colspan: "6", style: styles[:footer_iva]) +
          content_tag(:td, number_to_currency(total_con_iva, unit: "$", precision: 2), style: styles[:footer_iva_cell])
        end
      ].join.html_safe
    end
  end

  def render_glasscuttings_header(styles)
    content_tag :thead do
      content_tag :tr, style: styles[:header] do
        %w[Tipologia Tipo Espesor Color Alto Ancho Precio].map do |header|
          content_tag :th, header, style: styles[:header_cell]
        end.join.html_safe
      end
    end
  end

  def render_glasscuttings_body(glasscuttings, styles)
    content_tag :tbody do
      glasscuttings.each_with_index.map do |glass, idx|
        precio = glass.price.to_f
        
        content_tag :tr, style: "background: #{idx.even? ? styles[:row_even] : styles[:row_odd]};" do
          [
            glass.typology.present? ? glass.typology : '-',
            glass.glass_type.present? ? human_glass_type(glass.glass_type) : '-',
            glass.thickness.present? ? glass.thickness : '-',
            glass.color.present? ? human_glass_color(glass.color) : '-',
            glass.height.present? ? glass.height : '-',
            glass.width.present? ? glass.width : '-',
            precio > 0 ? number_to_currency(precio, unit: "$", precision: 2) : '-'
          ].map do |cell_content|
            content_tag :td, cell_content, style: styles[:cell]
          end.join.html_safe
        end
      end.join.html_safe
    end
  end

  def render_glasscuttings_footer(total, styles)
    total_con_iva = total * 1.21
    
    content_tag :tfoot do
      [
        content_tag(:tr) do
          content_tag(:td, "Total sin IVA:", colspan: "6", style: styles[:footer_total]) +
          content_tag(:td, number_to_currency(total, unit: "$", precision: 2), style: styles[:footer_total_cell])
        end,
        content_tag(:tr) do
          content_tag(:td, "Total con IVA:", colspan: "6", style: styles[:footer_iva]) +
          content_tag(:td, number_to_currency(total_con_iva, unit: "$", precision: 2), style: styles[:footer_iva_cell])
        end
      ].join.html_safe
    end
  end
end
