class Dvh < ApplicationRecord
  belongs_to :project
  #has_many :glasscuttings, dependent: :nullify

  # Si usás glassplates como modelos separados, agregalos también
  # belongs_to :glassplate1, class_name: "Glassplate", optional: true
  # belongs_to :glassplate2, class_name: "Glassplate", optional: true

  validates :innertube, :location, :height, :width, presence: true
  validates :height, :width, numericality: { greater_than: 0 }

  before_save :set_price_dvh

  def set_price_dvh
    Rails.logger.debug "Buscando precio para DVH:"
    area_m2 = (height.to_f / 1000) * (width.to_f / 1000)

    # Cristal 1
    Rails.logger.debug "Cristal 1: tipo=#{glasscutting1_type.inspect}, espesor=#{glasscutting1_thickness.inspect}, color=#{glasscutting1_color.inspect}"
    price1_record = GlassPrice.find_by(glass_type: glasscutting1_type, thickness: glasscutting1_thickness, color: glasscutting1_color)
    if price1_record.nil? || !price1_record.price_m2.present?
      Rails.logger.debug "No se encontró GlassPrice para cristal 1 o falta price_m2"
      price1 = 0
    else
      price1 = price1_record.price_m2
    end

    # Cristal 2
    Rails.logger.debug "Cristal 2: tipo=#{glasscutting2_type.inspect}, espesor=#{glasscutting2_thickness.inspect}, color=#{glasscutting2_color.inspect}"
    price2_record = GlassPrice.find_by(glass_type: glasscutting2_type, thickness: glasscutting2_thickness, color: glasscutting2_color)
    if price2_record.nil? || !price2_record.price_m2.present?
      Rails.logger.debug "No se encontró GlassPrice para cristal 2 o falta price_m2"
      price2 = 0
    else
      price2 = price2_record.price_m2
    end

    self.price = (area_m2 * (price1 + price2)).round(2)
    Rails.logger.debug "Seteando precio DVH: #{self.price} (area: #{area_m2}, price1: #{price1}, price2: #{price2})"
  end

end
