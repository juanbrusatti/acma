require 'axlsx'

class ScrapExporter
  def initialize(scraps)
    @scraps = scraps
  end

  def generate
    # Crear un workbook de Axlsx
    package = Axlsx::Package.new
    workbook = package.workbook

    # Definir estilos
    header_style = workbook.styles.add_style(
      bg_color: '4CAF50',
      fg_color: 'FFFFFF',
      alignment: { horizontal: :center, vertical: :center },
      border: { style: :thin, color: '000000' },
      font: { bold: true }
    )

    data_style = workbook.styles.add_style(
      alignment: { horizontal: :center, vertical: :center },
      border: { style: :thin, color: '000000' }
    )

    # Crear worksheet
    worksheet = workbook.add_worksheet(name: 'Retazos')

    # Escribir encabezados
    headers = ['Referencia', 'Tipo', 'Grosor', 'Color', 'Ancho (mm)', 'Alto (mm)', 'Obra de procedencia']
    worksheet.add_row headers, style: header_style

    # Ajustar ancho de columnas
    worksheet.column_widths 15, 12, 12, 12, 15, 15, 25

    # Escribir datos
    @scraps.each do |scrap|
      worksheet.add_row(
        [
          scrap.ref_number,
          scrap.scrap_type,
          scrap.thickness,
          scrap.color,
          scrap.width,
          scrap.height,
          scrap.input_work
        ],
        style: data_style
      )
    end

    # Crear archivo temporal y guardar
    temp_file = Tempfile.new(['scrap_export', '.xlsx'])
    package.serialize(temp_file.path)
    temp_file.path
  end
end
