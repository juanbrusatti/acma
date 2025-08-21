class Project < ApplicationRecord
  # Associations
  has_many :dvhs, dependent: :destroy
  has_many :glasscuttings, dependent: :destroy

  # Nested attributes for form handling
  accepts_nested_attributes_for :glasscuttings, allow_destroy: true
  accepts_nested_attributes_for :dvhs, allow_destroy: true

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

    # Fallback calculation - handle nil prices gracefully
    glasscutting_total = glasscuttings.sum { |g| g.price || 0 }
    dvh_total = dvhs.sum { |d| d.price || 0 }
    glasscutting_total + dvh_total
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

end
