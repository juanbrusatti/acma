class Glassplate < ApplicationRecord
  # Color validation
  validates :color, presence: true
  validates :color, inclusion: {
    in: ["INC", "STB", "GRS", "BRC", "BLS", "STG", "NTR"],
    message: "debe ser uno de: INC, STB, GRS, BRC, BLS, STG, NTR"
  }

  # Glass type validation
  validates :glass_type, presence: true
  validates :glass_type, inclusion: {
    in: ["LAM", "FLO", "COL"],
    message: "debe ser uno de: LAM, FLO, COL"
  }

  # Validations for width and height
  validates :width, :height, presence: true, numericality: { greater_than: 0 }

  # Thickness validation
  validates :thickness, presence: true
  validates :thickness, inclusion: {
    in: [ "3+3", "4+4", "5+5", "5mm" ],
    message: "debe ser uno de: 3+3, 4+4, 5+5, 5mm"
  }

  # Quantity validation
  validates :quantity, presence: true, numericality: { greater_than_or_equal_to: 0 }

  def full_description
    "#{glass_type} #{thickness} - #{color}"
  end
end
