require 'roo'

class ScrapImporter
  cattr_accessor :last_result

  COLUMN_INDEXES = {
    composition: 1, # COMPOSICION
    base: 2,        # BASE [mm]
    height: 3,      # ALTO [mm]
    reference: 5,   # REFERENCIA
    origin: 7       # ORIGEN / OBRA DE PROCEDENCIA
  }.freeze

  attr_reader :errors, :success_count, :total_rows

  def initialize(file_path)
    @file_path = file_path
    @errors = []
    @success_count = 0
    @total_rows = 0
  end

  def import
    return { success: false, errors: ["Archivo no encontrado"] } unless File.exist?(@file_path)

    begin
      spreadsheet = Roo::Spreadsheet.open(@file_path)
      sheet = spreadsheet.sheet(0)

      # Leer desde la fila 2 (asumiendo que la fila 1 es el encabezado)
      (2..sheet.last_row).each do |row_num|
        @total_rows += 1
        row_data = sheet.row(row_num)

        # Saltar filas vacías
        next if row_data.all?(&:nil?) || row_data.all? { |cell| cell.to_s.strip.empty? }

        composition = cell_string(row_data, COLUMN_INDEXES[:composition])
        base = cell_number(row_data, COLUMN_INDEXES[:base])
        alto = cell_number(row_data, COLUMN_INDEXES[:height])
        referencia = cell_string(row_data, COLUMN_INDEXES[:reference])
        origen = cell_string(row_data, COLUMN_INDEXES[:origin])

        # Validar que tengamos los datos mínimos
        if composition.blank? || base.nil? || base <= 0 || alto.nil? || alto <= 0 
          @errors << "Fila #{row_num}: Datos incompletos o inválidos (COMPOSICION: #{composition}, BASE: #{base}, ALTO: #{alto})"
          next
        end

        # Parsear la composición (ej: "COL 4+4 STB")
        parsed_data = parse_composition(composition)
        unless parsed_data
          @errors << "Fila #{row_num}: No se pudo parsear la composición '#{composition}'"
          next
        end

        # Usar la referencia del Excel si viene, o generar una automáticamente
        ref_number = referencia.present? ? referencia.to_i : generate_ref_number(parsed_data[:scrap_type], parsed_data[:thickness], parsed_data[:color])

        # Crear el scrap
        scrap = Scrap.new(
          ref_number: ref_number,
          scrap_type: parsed_data[:scrap_type],
          thickness: parsed_data[:thickness],
          color: parsed_data[:color],
          width: base,
          height: alto,
          input_work: origen.present? ? origen : nil
        )

        if scrap.save
          @success_count += 1
        else
          @errors << "Fila #{row_num}: #{scrap.errors.full_messages.join(', ')}"
        end
      end

      result = {
        success: @errors.empty?,
        success_count: @success_count,
        total_rows: @total_rows,
        errors: @errors
      }

      ScrapImporter.last_result = result
      result
    rescue Roo::HeaderRowNotFoundError
      { success: false, errors: ["No se encontró la fila de encabezado en el archivo"] }
    rescue => e
      { success: false, errors: ["Error al procesar el archivo: #{e.message}"] }
    end
  end

  private

  def parse_composition(composition)
    # Formato esperado: "COL 4+4 STB" o "LAM 3+3 INC" etc.
    # Patrón: TIPO ESPESOR COLOR (puede tener espacios adicionales)
    # Normalizar espacios múltiples a uno solo
    normalized = composition.gsub(/\s+/, ' ').strip.upcase

    # Patrón más flexible: permite espacios variables y variantes de '5mm' (p.ej. '5MM', '5 MM')
    match = normalized.match(/^([A-Z]{3})\s+((?:\d+\+\d+)|(?:\d+\s*MM))\s+([A-Z]{3})$/)

    return nil unless match

    scrap_type = match[1]
    raw_thickness = match[2].gsub(/\s+/, '').upcase
    # Normalizar el espesor al formato que espera el modelo (modelo usa '5mm' en minúsculas)
    thickness = (raw_thickness == '5MM') ? '5mm' : raw_thickness
    color = match[3]

    # Validar que los valores sean válidos según el modelo
    valid_scrap_types = ["LAM", "FLO", "COL"]
    valid_thicknesses = ["3+3", "4+4", "5+5", "5mm"]
    valid_colors = ["INC", "STB", "GRS", "BRC", "BLS", "STG", "NTR"]

    return nil unless valid_scrap_types.include?(scrap_type)
    return nil unless valid_thicknesses.include?(thickness)
    return nil unless valid_colors.include?(color)

    {
      scrap_type: scrap_type,
      thickness: thickness,
      color: color
    }
  end

  def generate_ref_number(scrap_type, thickness, color)
    # Generar ref_number automáticamente si no viene en el Excel
    last_scrap = Scrap.where(scrap_type: scrap_type, thickness: thickness, color: color).order(ref_number: :desc).first
    if last_scrap
      last_scrap_ref_number_int = last_scrap.ref_number.to_i
      last_scrap_ref_number_int += 1
      return last_scrap_ref_number_int.to_s
    else
      return "1"
    end
  end

  def cell_string(row, index)
    value = row[index]
    value.present? ? value.to_s.strip : nil
  end

  def cell_number(row, index)
    value = row[index]
    value.present? ? value.to_f : nil
  end
end

