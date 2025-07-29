class Project < ApplicationRecord
  # Associations
  has_many :dvhs
  has_many :glasscuttings, dependent: :destroy

  # Nested attributes for form handling
  accepts_nested_attributes_for :glasscuttings, allow_destroy: true
  accepts_nested_attributes_for :dvhs, allow_destroy: true

  # Validations
  validates :name, presence: true, length: { maximum: 100 }
  validates :phone, presence: true # Podriamos agregar un limite minimo de caracteres, como un telefono
  # validates :description, presence: true, length: { minimum: 0, maximum: 500 }
  # validates :status, presence: true, inclusion: { in: %w[Pendiente En\ Proceso Terminado] }
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
    
    # Fallback calculation
    glasscuttings.sum(&:price) + dvhs.sum(&:price)
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
end
