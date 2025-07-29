class Dvh < ApplicationRecord
  belongs_to :project
  #has_many :glasscuttings, dependent: :nullify

  # Si usás glassplates como modelos separados, agregalos también
  # belongs_to :glassplate1, class_name: "Glassplate", optional: true
  # belongs_to :glassplate2, class_name: "Glassplate", optional: true

  validates :innertube, :location, :height, :width, presence: true
  validates :height, :width, numericality: { greater_than: 0 }

  validates :location, inclusion: {
    in: ["DINTER", "JAMBA_I", "JAMBA_D", "UMBRAL"],
    message: "debe ser uno de: DINTEL, JAMBA_I, JAMBA_D, UMBRAL"
  }

  validates :innertube, inclusion: {
    in: [6, 9, 12, 20],
    message: "debe ser uno de: 6, 9, 12, 20"
  }

  validates :glasscutting1_type, :glasscutting1_thickness, :glasscutting1_color,
  :glasscutting2_type, :glasscutting2_thickness, :glasscutting2_color, presence: true

  validates :glasscutting1_type, :glasscutting2_type, inclusion: {
    in: ["LAM", "FLO", "COL"],
    message: "debe ser uno de: LAM, FLO, COL"
  }

  validates :glasscutting1_thickness, :glasscutting2_thickness, inclusion: {
    in: ["3+3", "4+4", "5+5", "5mm"],
    message: "debe ser uno de: 3+3, 4+4, 5+5, 5mm"
  }

  validates :glasscutting1_color, :glasscutting2_color, inclusion: {
    in: ["INC", "STB", "GRS", "BRC", "BLS", "STG", "NTR"],
    message: "debe ser uno de: INC, STB, GRS, BRC, BLS, STG, NTR"
  }

  validates :glasscutting1_color, :glasscutting2_color, presence: true

  before_save :set_price_dvh

  def set_price_dvh
    Rails.logger.debug "Buscando precio para DVH:"
    area_m2 = (height.to_f / 1000) * (width.to_f / 1000)

    # Glasscutting 1
    Rails.logger.debug "Cristal 1: tipo=#{glasscutting1_type.inspect}, espesor=#{glasscutting1_thickness.inspect}, color=#{glasscutting1_color.inspect}"
    price1_record = GlassPrice.find_by(glass_type: glasscutting1_type, thickness: glasscutting1_thickness, color: glasscutting1_color)
    if price1_record.nil? || !price1_record.selling_price.present?
      Rails.logger.debug "No se encontró GlassPrice para cristal 1 o falta selling_price"
      price1 = 0
    else
      price1 = price1_record.selling_price
    end

    # Glasscutting 2
    Rails.logger.debug "Cristal 2: tipo=#{glasscutting2_type.inspect}, espesor=#{glasscutting2_thickness.inspect}, color=#{glasscutting2_color.inspect}"
    price2_record = GlassPrice.find_by(glass_type: glasscutting2_type, thickness: glasscutting2_thickness, color: glasscutting2_color)
    if price2_record.nil? || !price2_record.selling_price.present?
      Rails.logger.debug "No se encontró GlassPrice para cristal 2 o falta selling_price"
      price2 = 0
    else
      price2 = price2_record.selling_price
    end

    self.price = (area_m2 * (price1 + price2)).round(2)
    Rails.logger.debug "Seteando precio DVH: #{self.price} (area: #{area_m2}, price1: #{price1}, price2: #{price2})"
  end

end
