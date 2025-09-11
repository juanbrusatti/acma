class OfficialRateHistory < ApplicationRecord
  validates :rate, presence: true, numericality: { greater_than: 0 }
  validates :source, presence: true
  validates :date, presence: true, uniqueness: true
  
  scope :recent, -> { order(date: :desc) }
  scope :by_date_range, ->(start_date, end_date) { where(date: start_date..end_date) }
  scope :automatic, -> { where(is_manual: false) }
  scope :manual, -> { where(is_manual: true) }
  
  # Obtener la cotización del día anterior
  def self.previous_day_rate
    yesterday = Date.current - 1.day
    find_by(date: yesterday)&.rate
  end
  
  # Obtener la cotización de hoy
  def self.today_rate
    find_by(date: Date.current)&.rate
  end
  
  # Obtener la última cotización disponible
  def self.latest_rate
    recent.first&.rate
  end
  
  # Crear o actualizar la cotización para una fecha específica
  def self.create_or_update_rate(date:, rate:, source:, notes: nil, is_manual: false)
    record = find_or_initialize_by(date: date)
    record.assign_attributes(
      rate: rate,
      source: source,
      notes: notes,
      is_manual: is_manual
    )
    record.save!
    record
  end
  
  # Obtener estadísticas de las cotizaciones
  def self.statistics(days: 30)
    recent_records = recent.limit(days)
    return {} if recent_records.empty?
    
    rates = recent_records.pluck(:rate)
    {
      current_rate: rates.first,
      average_rate: rates.sum / rates.size,
      min_rate: rates.min,
      max_rate: rates.max,
      volatility: rates.max - rates.min,
      days_count: rates.size
    }
  end
  
  # Formatear la tasa para mostrar
  def formatted_rate
    format_argentine_currency(rate, unit: "$", precision: 2)
  end
  
  # Verificar si es una cotización manual
  def manual?
    is_manual?
  end
  
  # Verificar si es una cotización automática
  def automatic?
    !is_manual?
  end
end
