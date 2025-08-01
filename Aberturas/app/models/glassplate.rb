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

  # New field validations
  validates :thickness, presence: true
  validates :thickness, inclusion: {
    in: [ "3+3", "4+4", "5+5", "5mm" ],
    message: "debe ser uno de: 3+3, 4+4, 5+5, 5mm"
  }
  validates :status, inclusion: { in: %w[disponible reservado usado], allow_nil: true }
  validates :is_scrap, inclusion: { in: [true, false] }

  # Scopes
  scope :complete_sheets, -> { where(is_scrap: false) }
  scope :scraps, -> { where(is_scrap: true) }
  scope :available, -> { where(status: 'disponible') }
  scope :reserved, -> { where(status: 'reservado') }

  # Instance methods
  def measures
    "#{width.to_i}x#{height.to_i}"
  end

  def full_description
    "#{glass_type} #{thickness} - #{color}"
  end

  def available?
    status == 'disponible'
  end

  def reserved?
    status == 'reservado'
  end
end
