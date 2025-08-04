class Project < ApplicationRecord
  # Associations
  has_many :dvhs
  has_many :glasscuttings, dependent: :destroy

  # Nested attributes for form handling
  accepts_nested_attributes_for :glasscuttings, allow_destroy: true
  accepts_nested_attributes_for :dvhs, allow_destroy: true

  # Callbacks
  after_save :assign_typologies

  # Validations
  validates :name, presence: { message: "El nombre del proyecto no puede estar en blanco", full_message: false }, length: { maximum: 100, message: "no puede tener más de %{count} caracteres", full_message: false }
  validates :phone, presence: { message: "El teléfono no puede estar en blanco", full_message: false }
   # validates :description, presence: true, length: { minimum: 0, maximum: 500 }
  validates :status, presence: { message: "no puede estar en blanco", full_message: false }, inclusion: { 
    in: %w[Pendiente En\ Proceso Terminado], 
    message: "debe ser uno de: Pendiente, En Proceso, Terminado" 
  }
  # validates :delivery_date, presence: true, comparison: { greater_than: -> { Date.current } }, if: -> { status == "Pendiente" }

  # Scopes for filtering projects by status and dates
  scope :active, -> { where(status: "En Proceso") }
  scope :completed, -> { where(status: "Terminado") }
  scope :pending, -> { where(status: "Pendiente") }
  scope :overdue, -> { where("delivery_date < ?", Date.current) }
  scope :upcoming, -> { where("delivery_date >= ?", Date.current) }

  # Instance methods

  # Check if project is overdue (delivery date passed and not completed)
  def overdue?
    delivery_date.present? && delivery_date < Date.current && status != "Terminado"
  end

  # Calculate days until delivery date
  def days_until_delivery
    return nil unless delivery_date.present?
    (delivery_date - Date.current).to_i
  end

  # Calculate subtotal (use saved price_without_iva or fallback to calculation)
  def subtotal
    # If we have a saved price without IVA, use it directly
    return price_without_iva if price_without_iva.present?
    
    # If we don't have a saved price without IVA, calculate it
    # Handle nil prices by filtering them out before summing
    glasscuttings_total = glasscuttings.map(&:price).compact.sum
    dvhs_total = dvhs.map(&:price).compact.sum
    glasscuttings_total + dvhs_total
  end

  # Calculate IVA (21% of subtotal)
  def iva
    subtotal * 0.21
  end

  # Calculate total including IVA
  def total
    subtotal + iva
  end

  # Alias methods for clarity
  def precio_sin_iva
    subtotal
  end

  def precio_con_iva
    total
  end

  # Return color class for status display in views
  def status_color
    case status
    when "Terminado"
      "green"
    when "En Proceso"
      "blue"
    when "Pendiente"
      "yellow"
    else
      "gray"
    end
  end

  private

  # Assign sequential typologies to glasscuttings and DVHs
  def assign_typologies
    counter = 1
    
    # First, assign typologies to glasscuttings (reset all)
    glasscuttings.order(:id).each do |glasscutting|
      glasscutting.update_column(:typology, "V#{counter}")
      counter += 1
    end
    
    # Then, assign typologies to DVHs continuing the count (reset all)
    dvhs.order(:id).each do |dvh|
      dvh.update_column(:typology, "V#{counter}")
      counter += 1
    end
  end
end
