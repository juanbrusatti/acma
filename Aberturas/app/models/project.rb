class Project < ApplicationRecord
  # Validaciones
  validates :name, presence: true, length: { minimum: 3, maximum: 100 }
  validates :description, presence: true, length: { minimum: 10, maximum: 500 }
  validates :status, presence: true, inclusion: { in: %w[Pendiente En\ Proceso Terminado] }
  validates :delivery_date, presence: true, comparison: { greater_than: Date.current }, allow_nil: true

  # Scopes útiles
  scope :active, -> { where(status: 'En Proceso') }
  scope :completed, -> { where(status: 'Terminado') }
  scope :pending, -> { where(status: 'Pendiente') }
  scope :overdue, -> { where('delivery_date < ?', Date.current) }
  scope :upcoming, -> { where('delivery_date >= ?', Date.current) }

  # Métodos de instancia
  def overdue?
    delivery_date.present? && delivery_date < Date.current && status != 'Terminado'
  end

  def days_until_delivery
    return nil unless delivery_date.present?
    (delivery_date - Date.current).to_i
  end

  def status_color
    case status
    when 'Terminado'
      'green'
    when 'En Proceso'
      'blue'
    when 'Pendiente'
      'yellow'
    else
      'gray'
    end
  end
end
