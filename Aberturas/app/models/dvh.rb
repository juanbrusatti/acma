class Dvh < ApplicationRecord
  belongs_to :project
  #has_many :glasscuttings, dependent: :nullify

  # Si usás glassplates como modelos separados, agregalos también
  # belongs_to :glassplate1, class_name: "Glassplate", optional: true
  # belongs_to :glassplate2, class_name: "Glassplate", optional: true

  validates :height, presence: { message: "El alto del vidrio no puede estar en blanco" }
  validates :width, presence: { message: "El ancho del vidrio no puede estar en blanco" }
  validates :height, numericality: { greater_than: 0, message: "El alto debe ser mayor que 0" }
  validates :width, numericality: { greater_than: 0, message: "El ancho debe ser mayor que 0" }

  validates :location, inclusion: {
    in: ["DINTER", "JAMBA_I", "JAMBA_D", "UMBRAL"],
    message: "La ubicación del vidrio no es valida"
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
end
