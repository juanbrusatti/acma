class Glassplate < ApplicationRecord
  # Color validation
  validates :color, presence: true
  validates :color, inclusion: {
    in: [ "transparente", "gris", "azul", "verde", "negro", "plata", "N/A" ],
    message: "debe ser uno de: transparente, gris, azul, verde, negro, plata, N/A"
  }

  # Type validation
  validates :type, presence: true
  validates :type, inclusion: {
    in: [ "Incoloro", "Laminado 3+3", "DVH 4/9/4", "Espejo", "Templado", "Doble" ],
    message: "debe ser uno de: Incoloro, Laminado 3+3, DVH 4/9/4, Espejo, Templado, Doble"
  }

  # Validations for width and height
  validates :width, :height, presence: true, numericality: { greater_than: 0 }

  # New field validations
  validates :thickness, presence: true
  validates :quantity, presence: true, numericality: { greater_than_or_equal_to: 0 }
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
    "#{type} #{thickness} - #{color}"
  end

  def available?
    status == 'disponible'
  end

  def reserved?
    status == 'reservado'
  end
end
