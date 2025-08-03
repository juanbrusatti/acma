class Dvh < ApplicationRecord
  belongs_to :project
  #has_many :glasscuttings, dependent: :nullify

  # Callbacks to update typologies when DVHs change
  after_create :update_project_typologies
  after_destroy :update_project_typologies

  # Si usás glassplates como modelos separados, agregalos también
  # belongs_to :glassplate1, class_name: "Glassplate", optional: true
  # belongs_to :glassplate2, class_name: "Glassplate", optional: true

  validates :height, presence: { message: "El alto del vidrio no puede estar en blanco" }
  validates :width, presence: { message: "El ancho del vidrio no puede estar en blanco" }
  validates :height, numericality: { greater_than: 0, message: "El alto debe ser mayor que 0" }
  validates :width, numericality: { greater_than: 0, message: "El ancho debe ser mayor que 0" }

  validates :location, inclusion: {
    in: ["DINTEL", "JAMBA_I", "JAMBA_D", "UMBRAL"],
    message: "La ubicación del vidrio no es valida",
  }

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

  # Set price if not provided by frontend
  before_save :ensure_price_is_set

  private

  # Ensure DVH has a price - either from frontend or calculated here
  def ensure_price_is_set
    return if price.present? && price > 0  # Price already set by frontend
    
    # Fallback: calculate price if not provided by frontend
    area_m2 = (height.to_f / 1000) * (width.to_f / 1000)
    perimeter_m = 2 * ((height.to_f / 1000) + (width.to_f / 1000))

    # Get glass prices
    price1 = get_glass_price(glasscutting1_type, glasscutting1_thickness, glasscutting1_color)
    price2 = get_glass_price(glasscutting2_type, glasscutting2_thickness, glasscutting2_color)

    # Calculate total price: glass area + innertube total
    glass_price = area_m2 * (price1 + price2)
    innertube_total_price = AppConfig.calculate_innertube_total_price(innertube, perimeter_m)
    
    self.price = (glass_price + innertube_total_price).round(2)
  end

  # Helper method to get glass price
  def get_glass_price(type, thickness, color)
    price_record = GlassPrice.find_by(glass_type: type, thickness: thickness, color: color)
    price_record&.selling_price || 0.0
  end

  # Update project typologies when DVH changes
  def update_project_typologies
    project.send(:assign_typologies) if project
  end

end
