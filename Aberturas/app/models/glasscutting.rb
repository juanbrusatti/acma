class Glasscutting < ApplicationRecord
  belongs_to :project 
  belongs_to :glassplate, optional: true 

  # Validates that height and width are present and greater than 0
  validates :height, :width, presence: true, numericality: { greater_than: 0 } 
  # Validates that glass_type, thickness, color, and location are present
  validates :glass_type, :thickness, :color, :location, presence: true 

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
