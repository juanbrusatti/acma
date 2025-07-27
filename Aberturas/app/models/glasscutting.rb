class Glasscutting < ApplicationRecord
  belongs_to :project 
  belongs_to :glassplate, optional: true 

  # Validates that height and width are present and greater than 0
  validates :height, presence: { message: "El alto del vidrio no puede estar en blanco" }, numericality: { greater_than: 0, message: "El alto debe ser mayor que 0" } 
  validates :width, presence: { message: "El ancho del vidrio no puede estar en blanco" }, numericality: { greater_than: 0, message: "El ancho debe ser mayor que 0" } 
  # Validates that glass_type, thickness, color, and location are present
  validates :glass_type, presence: { message: "El tipo de vidrio no puede estar en blanco" } 
  validates :thickness, presence: { message: "El espesor del vidrio no puede estar en blanco" } 
  validates :color, presence: { message: "El color del vidrio no puede estar en blanco" } 
  validates :location, presence: { message: "La ubicación del vidrio no puede estar en blanco" } 
  validates :color, inclusion: {
    in: ["INC", "STB", "GRS", "BRC", "BLS", "STG", "NTR"],
    message: "Color de vidrio no valido"
  }

  validates :glass_type, inclusion: {
    in: ["LAM", "FLO", "COL"],
    message: "El tipo de vidrio no es valido"
  }

  validates :thickness, inclusion: {
    in: ["3+3", "4+4", "5+5", "5mm"],
    message: "El grosor del vidrios no es valido"
  }

  validates :location, inclusion: {
    in: ["DINTER", "JAMBA_I", "JAMBA_D", "UMBRAL"],
    message: "La ubicación del vidrio no es valida"
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
    if !price_record.price_m2.present?
      Rails.logger.debug "El registro no tiene price_m2"
      return
    end
    if !height.present? || !width.present?
      Rails.logger.debug "Faltan height o width"
      return
    end
    area_m2 = (height.to_f / 1000) * (width.to_f / 1000)
    self.price = (area_m2 * price_record.price_m2).round(2)
    Rails.logger.debug "Seteando precio: #{self.price}"
  end

end
