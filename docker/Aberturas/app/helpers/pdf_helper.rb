module PdfHelper
  # Configuración común para PDFs
  def pdf_common_options
    {
      layout: "pdf",
      enable_local_file_access: true,
      margin: { top: 2, bottom: 10, left: 12, right: 10 },
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
        %w[Tipologia Cristal\ 1 Cristal\ 2 Camara Alto Ancho Cantidad Precio].map do |header|
          content_tag :th, header, style: styles[:header_cell]
        end.join.html_safe
      end
    end
  end

  def render_dvh_body(dvhs, styles)
    # Agrupar DVH por todos los atributos relevantes, incluyendo type_opening (Abertura)
    grouped = dvhs.group_by do |dvh|
      [
        dvh.typology,
        [dvh.glasscutting1_type, dvh.glasscutting1_thickness, dvh.glasscutting1_color].compact.join(' / '),
        [dvh.glasscutting2_type, dvh.glasscutting2_thickness, dvh.glasscutting2_color].compact.join(' / '),
        dvh.innertube,
        dvh.height,
        dvh.width,
        dvh.price
      ]
    end
    idx = -1
    content_tag :tbody do
      grouped.map do |attrs, dvh_group|
        idx += 1
        cantidad = dvh_group.size
        precio_unitario = attrs[6].to_f
        precio_total = precio_unitario * cantidad
        row_values = attrs[0..5] + [cantidad] + [precio_total]
        content_tag :tr, style: "background: #{idx.even? ? styles[:row_even] : styles[:row_odd]};" do
          row_values.each_with_index.map do |cell_content, i|
            if i == 7 # Solo la última columna (precio total)
              formatted_content = format_argentine_currency(cell_content, unit: "$", precision: 2)
            else
              # Si es numérico, mostrar como número plano (con coma decimal si es float)
              formatted_content = cell_content.is_a?(Float) ? sprintf('%.2f', cell_content).tr('.', ',') : cell_content
            end
            content_tag :td, formatted_content, style: styles[:cell]
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
          content_tag(:td, "Total sin IVA:", colspan: "7", style: styles[:footer_total]) +
          content_tag(:td, number_to_currency(total, unit: "$", precision: 2), style: styles[:footer_total_cell])
        end,
        content_tag(:tr) do
          content_tag(:td, "Total con IVA:", colspan: "7", style: styles[:footer_iva]) +
          content_tag(:td, number_to_currency(total_con_iva, unit: "$", precision: 2), style: styles[:footer_iva_cell])
        end
      ].join.html_safe
    end
  end

  def render_glasscuttings_header(styles)
    content_tag :thead do
      content_tag :tr, style: styles[:header] do
        %w[Tipologia Tipo Espesor Color Alto Ancho Cantidad Precio].map do |header|
          content_tag :th, header, style: styles[:header_cell]
        end.join.html_safe
      end
    end
  end

  def render_glasscuttings_body(glasscuttings, styles)
    # Agrupar vidrios simples por todos los atributos relevantes, incluyendo type_opening (Abertura)
    grouped = glasscuttings.group_by do |glass|
      [
        glass.typology,
        glass.glass_type,
        glass.thickness,
        glass.color,
        glass.height,
        glass.width,
        glass.price
      ]
    end
    idx = -1
    content_tag :tbody do
      grouped.map do |attrs, group|
        idx += 1
        cantidad = group.size
        precio_unitario = attrs[6].to_f
        precio_total = precio_unitario * cantidad
        row_values = [
          attrs[0].present? ? attrs[0] : '-',
          attrs[1].present? ? attrs[1] : '-',
          attrs[2].present? ? attrs[2] : '-',
          attrs[3].present? ? attrs[3] : '-',
          attrs[4].present? ? attrs[4] : '-',
          attrs[5].present? ? attrs[5] : '-',
          cantidad,
          precio_total
        ]
        content_tag :tr, style: "background: #{idx.even? ? styles[:row_even] : styles[:row_odd]};" do
          row_values.each_with_index.map do |cell_content, i|
            if i == 7 # Solo la última columna (precio total)
              formatted_content = number_to_currency(cell_content, unit: "$", precision: 2)
            else
              formatted_content = cell_content.is_a?(Float) ? sprintf('%.2f', cell_content).tr('.', ',') : cell_content
            end
            content_tag :td, formatted_content, style: styles[:cell]
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
          content_tag(:td, "Total sin IVA:", colspan: "7", style: styles[:footer_total]) +
          content_tag(:td, number_to_currency(total, unit: "$", precision: 2), style: styles[:footer_total_cell])
        end,
        content_tag(:tr) do
          content_tag(:td, "Total con IVA:", colspan: "7", style: styles[:footer_iva]) +
          content_tag(:td, number_to_currency(total_con_iva, unit: "$", precision: 2), style: styles[:footer_iva_cell])
        end
      ].join.html_safe
    end
  end

  def render_glass(name, dvhs, glasscuttings)
    return "" if dvhs.blank?
    labels = dvhs.map do |dvh|
    content_tag :div, style: "width: 72mm; height: 50mm; display: inline-block; vertical-align: top; margin: 1%; box-sizing: border-box; background: #fff; text-align: left;" do
        [
          content_tag(:div, style: "display: flex; justify-content: space-between; align-items: flex-start; margin-bottom: 6px;") do
            [
              content_tag(:div, name, style: "font-weight: bold; font-size: 15px; color: #333;"),
              content_tag(:div, "DVH", style: "font-size: 15px; color: #666;")
            ].join.html_safe
          end,
          content_tag(:div, dvh.typology, style: "font-size: 15px; color: #000; margin-bottom: 5px;"),
          content_tag(:div, "#{[dvh.glasscutting1_type, dvh.glasscutting1_thickness, dvh.glasscutting1_color].compact.join(' ')} / #{dvh.innertube} / #{[dvh.glasscutting2_type, dvh.glasscutting2_thickness, dvh.glasscutting2_color].compact.join(' ')}", style: "font-size: 15px; line-height: 1.3; margin-bottom: 8px;"),
          content_tag(:div, "#{dvh.width.to_s.rjust(4, '0')} x #{dvh.height.to_s.rjust(4, '0')}", style: "font-size: 15px; color: #000; margin-bottom: 10px;"),
          image_tag("file://#{Rails.root.join('public', 'logo-ar-transparente.png')}", alt: "Logo AR", style: "height: 90px; width: auto; float: right; margin-top: -20px;")        
        ].join.html_safe
      end
    end

    labels += glasscuttings.map do |glass|
    content_tag :div, style: "width: 72mm; height: 50mm; display: inline-block; vertical-align: top; margin: 1%; box-sizing: border-box; background: #fff; text-align: left;" do
          [
          content_tag(:div, style: "display: flex; justify-content: space-between; align-items: flex-start; margin-bottom: 6px;") do
            [
              content_tag(:div, name, style: "font-weight: bold; font-size: 15px; color: #333;"),
              content_tag(:div, 'Simple', style: "font-size: 15px; color: #666;")
            ].join.html_safe
          end,
          content_tag(:div, glass.typology, style: "font-size: 15px; color: #000; margin-bottom: 5px;"),
          content_tag(:div, "#{[glass.glass_type, glass.thickness, glass.color].compact.join(' ')}", style: "font-size: 15px; line-height: 1.3; margin-bottom: 8px;"),
          content_tag(:div, "#{glass.width.to_s.rjust(4, '0')} x #{glass.height.to_s.rjust(4, '0')}", style: "font-size: 15px; color: #000; margin-bottom: 10px;"),
          image_tag("file://#{Rails.root.join('public', 'logo-ar-transparente.png')}", alt: "Logo AR", style: "height: 90px; width: auto; float: right; margin-top: -20px;")
        ].join.html_safe
      end
    end

    html = "<div style=\"page-break-before: always;\"></div>"
    total_pages = (labels.size / 4.0).ceil
    labels.each_slice(4).with_index do |group, idx|
      # Si hay menos de 4 etiquetas, agregamos "espacios vacíos" invisibles
      while group.size < 4
        group << content_tag(:div, '', style: "width: 72mm; height: 50mm; display: inline-block; margin: 1%; visibility: hidden;")
      end

      html << content_tag(
        :div,
        group.join.html_safe,
        style: "page-break-inside: avoid; width: 100%; text-align: center;"
      )

      html << '<div style="page-break-after: always;"></div>' unless idx == (total_pages - 1)
    end
    html.html_safe
  end

  def render_plates_table(glasscuttings, dvhs)
    styles = table_styles
    # Encabezado personalizado
    thead = content_tag(:thead) do
      content_tag(:tr, style: styles[:header]) do
        %w[Clase Cardinal Tipo Color Grosor Ancho Alto Origen].map do |header|
          content_tag(:th, header, style: styles[:header_cell])
        end.join.html_safe
      end
    end

    # Filas de glasscuttings (simples)
    simple_rows = glasscuttings.map do |glass|
      row_values = [
        'Simple',
        '1/1',
        glass.glass_type.present? ? glass.glass_type : '-',
        glass.color.present? ? glass.color : '-',
        glass.thickness.present? ? glass.thickness : '-',
        glass.width.present? ? glass.width : '-',
        glass.height.present? ? glass.height : '-',
        glass.respond_to?(:origin) ? glass.origin : '-'
      ]
      content_tag :tr, style: "background: #{glasscuttings.index(glass).even? ? styles[:row_even] : styles[:row_odd]};" do
        row_values.map { |cell| content_tag(:td, cell, style: styles[:cell]) }.join.html_safe
      end
    end

    # Filas de dvhs (cada DVH se descompone en dos placas)
    dvh_rows = dvhs.flat_map.with_index do |dvh, idx|
      [
        # Primer placa
        [
          'DVH',
          '1/2',
          dvh.glasscutting1_type.present? ? dvh.glasscutting1_type : '-',
          dvh.glasscutting1_color.present? ? dvh.glasscutting1_color : '-',
          dvh.glasscutting1_thickness.present? ? dvh.glasscutting1_thickness : '-',
          dvh.width.present? ? dvh.width : '-',
          dvh.height.present? ? dvh.height : '-',
          dvh.respond_to?(:origin) ? dvh.origin : '-'
        ],
        # Segunda placa
        [
          'DVH',
          '2/2',
          dvh.glasscutting2_type.present? ? dvh.glasscutting2_type : '-',
          dvh.glasscutting2_color.present? ? dvh.glasscutting2_color : '-',
          dvh.glasscutting2_thickness.present? ? dvh.glasscutting2_thickness : '-',
          dvh.width.present? ? dvh.width : '-',
          dvh.height.present? ? dvh.height : '-',
          dvh.respond_to?(:origin) ? dvh.origin : '-'
        ]
      ].map.with_index do |row_values, i|
        content_tag :tr, style: "background: #{(idx * 2 + i).even? ? styles[:row_even] : styles[:row_odd]};" do
          row_values.map { |cell| content_tag(:td, cell, style: styles[:cell]) }.join.html_safe
        end
      end
    end

    tbody = content_tag(:tbody) do
      (simple_rows + dvh_rows).join.html_safe
    end

    title = content_tag(:h2, "Vidrios del proyecto", style: "text-align: center; margin-top: 40px; margin-bottom: 20px; font-size: 18px; color: #333;")
    table_html = content_tag(:table, thead.concat(tbody).html_safe, border: "0", cellspacing: "0", cellpadding: "0", style: styles[:table])
    (
      '<div style="page-break-before: always;"></div>' +
      title +
      table_html +
      '<div style="page-break-after: always;"></div>'
    ).html_safe
  end

end

