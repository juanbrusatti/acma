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
    message: "debe ser uno de: DINTER, JAMBA_I, JAMBA_D, UMBRAL"
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

end
