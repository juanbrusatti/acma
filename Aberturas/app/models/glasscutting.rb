class Glasscutting < ApplicationRecord
  belongs_to :project 
  belongs_to :glassplate, optional: true 

  # Validates that height and width are present and greater than 0
  validates :height, :width, presence: true, numericality: { greater_than: 0 } 
  # Validates that glass_type, thickness, color, and location are present
  validates :glass_type, :thickness, :color, :location, presence: true 
  validates :color, inclusion: {
    in: ["INC", "STB", "GRS", "BRC", "BLS", "STG", "NTR"],
    message: "debe ser uno de: INC, STB, GRS, BRC, BLS, STG, NTR"
  }

  validates :glass_type, inclusion: {
    in: ["LAM", "FLO", "COL"],
    message: "debe ser uno de: LAM, FLO, COL"
  }

  validates :thickness, inclusion: {
    in: ["3+3", "4+4", "5+5", "5mm"],
    message: "debe ser uno de: 3+3, 4+4, 5+5, 5mm"
  }

  validates :location, inclusion: {
    in: ["DINTEL", "JAMBA_I", "JAMBA_D", "UMBRAL"],
    message: "debe ser uno de: DINTEL, JAMBA_I, JAMBA_D, UMBRAL"
  }

  before_save :set_price 

  def set_price
    Rails.logger.debug "Buscando precio para: tipo=#{glass_type.inspect}, espesor=#{thickness.inspect}, color=#{color.inspect}"
    price_record = GlassPrice.find_by(glass_type: glass_type, thickness: thickness, color: color)
    if price_record.nil?
      Rails.logger.debug "No se encontró GlassPrice para esa combinación"
      return
    end
    Rails.logger.debug "Registro encontrado: #{price_record.inspect}"
    if !price_record.selling_price.present?
      Rails.logger.debug "El registro no tiene selling_price"
      return
    end
    if !height.present? || !width.present?
      Rails.logger.debug "Faltan height o width"
      return
    end
    area_m2 = (height.to_f / 1000) * (width.to_f / 1000)
    self.price = (area_m2 * price_record.selling_price).round(2)
    Rails.logger.debug "Seteando precio: #{self.price}"
  end

end
