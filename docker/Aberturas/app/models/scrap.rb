class Scrap < ApplicationRecord

  # ref_number validation
  validates :ref_number, presence: true

  # Color validation
  validates :color, presence: true
  validates :color, inclusion: { in: ["INC", "STB", "GRS", "BRC", "BLS", "STG", "NTR"] }

  # Glass type validation
  validates :scrap_type, presence: true
  validates :scrap_type, inclusion: { in: ["LAM", "FLO", "COL"] }

  # Validations for width and height
  validates :height, presence: true, numericality: { greater_than: 0 }
  validates :width, presence: true, numericality: { greater_than: 0 }
  
  # Thickness validation
  validates :thickness, presence: true
  validates :thickness, inclusion: { in: [ "3+3", "4+4", "5+5", "5mm" ] }

  # Output work validation
  validates :output_work, presence: true

  # Status validation
  validates :status, presence: true
  validates :status, inclusion: { in: ["Disponible", "Reservado"] }

end
