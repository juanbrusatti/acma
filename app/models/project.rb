  # Scopes útiles
  scope :active, -> { where(status: 'En Proceso') }
  scope :completed, -> { where(status: 'Terminado') }
  scope :pending, -> { where(status: 'Pendiente') }
  scope :overdue, -> { where('delivery_date < ?', Date.current) }
  scope :upcoming, -> { where('delivery_date >= ?', Date.current) }

  # Scope para filtrado y orden
  scope :filtered, ->(params) {
    projects = all
    projects = projects.where(status: params[:status]) if params[:status].present?
    projects.order(created_at: :desc)
  }

  # Métodos de instancia
  def overdue?
    delivery_date.present? && delivery_date < Date.current && status != 'Terminado'
  end

  def days_until_delivery
    return nil unless delivery_date.present?
    (delivery_date - Date.current).to_i
  end 