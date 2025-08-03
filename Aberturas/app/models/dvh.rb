class Dvh < ApplicationRecord
  belongs_to :project
  #has_many :glasscuttings, dependent: :nullify

  validates :height, presence: { message: "El alto del vidrio no puede estar en blanco" }
  validates :width, presence: { message: "El ancho del vidrio no puede estar en blanco" }
  validates :height, numericality: { greater_than: 0, message: "El alto debe ser mayor que 0" }
  validates :width, numericality: { greater_than: 0, message: "El ancho debe ser mayor que 0" }
  validates :typology, presence: { message: "La tipología del DVH no puede estar en blanco" }

  validates :innertube, inclusion: {
    in: [6, 9, 12, 20],
    message: "La camara del vidrio no es valida"
  }

  validates :glasscutting1_type, presence: { message: "El tipo de vidrio 1 no puede estar en blanco" }
  validates :glasscutting1_thickness, presence: { message: "El espesor del vidrio 1 no puede estar en blanco" }
  validates :glasscutting1_color, presence: { message: "El color del vidrio 1 no puede estar en blanco" }
  validates :glasscutting2_type, presence: { message: "El tipo de vidrio 2 no puede estar en blanco" }
  validates :glasscutting2_thickness, presence: { message: "El espesor del vidrio 2 no puede estar en blanco" }
  validates :glasscutting2_color, presence: { message: "El color del vidrio 2 no puede estar en blanco" }

  validates :glasscutting1_type, inclusion: {
    in: ["LAM", "FLO", "COL"],
    message: "El tipo de vidrio 1 no es valido"
  }

  validates :glasscutting2_type, inclusion: {
    in: ["LAM", "FLO", "COL"],
    message: "El tipo de vidrio 2 no es valido"
  }

  validates :glasscutting1_thickness, inclusion: {
    in: ["3+3", "4+4", "5+5", "5mm"],
    message: "El grosor del vidrio 1 no es valido"
  }

  validates :glasscutting2_thickness, inclusion: {
    in: ["3+3", "4+4", "5+5", "5mm"],
    message: "El grosor del vidrio 2 no es valido"
  }

  validates :glasscutting1_color, inclusion: {
    in: ["INC", "STB", "GRS", "BRC", "BLS", "STG", "NTR"],
    message: "El color del vidrio 1 no es valido"
  }

  validates :glasscutting2_color, inclusion: {
    in: ["INC", "STB", "GRS", "BRC", "BLS", "STG", "NTR"],
    message: "El color del vidrio 2 no es valido"
  }

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
