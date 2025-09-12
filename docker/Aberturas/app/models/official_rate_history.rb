class OfficialRateHistory < ApplicationRecord
  # Validations
  validates :rate, presence: true, numericality: { greater_than: 0 }
  validates :source, presence: true
  validates :rate_date, presence: true
  validates :rate_date, uniqueness: { scope: :source }

  # Scopes
  scope :by_date, ->(date) { where(rate_date: date) }
  scope :by_source, ->(source) { where(source: source) }
  scope :manual_updates, -> { where(manual_update: true) }
  scope :automatic_updates, -> { where(manual_update: false) }
  scope :recent, -> { order(rate_date: :desc) }
  scope :significant_changes, -> { where('change_percentage > ?', 5.0) }

  # Class methods
  def self.latest_rate
    recent.first&.rate
  end

  def self.latest_rate_by_source(source)
    by_source(source).recent.first&.rate
  end

  def self.yesterday_rate
    yesterday = Date.current - 1.day
    by_date(yesterday).first&.rate
  end

  def self.today_rate
    today = Date.current
    by_date(today).first&.rate
  end

  def self.create_with_change_calculation(attributes)
    previous_rate = latest_rate
    new_rate = attributes[:rate]
    
    change_percentage = if previous_rate && previous_rate > 0
      ((new_rate - previous_rate) / previous_rate * 100).round(2)
    else
      0.0
    end

    create(attributes.merge(
      previous_rate: previous_rate,
      change_percentage: change_percentage
    ))
  end

  def self.statistics_for_period(start_date, end_date)
    rates = where(rate_date: start_date..end_date).order(:rate_date)
    return {} if rates.empty?

    {
      min_rate: rates.minimum(:rate),
      max_rate: rates.maximum(:rate),
      avg_rate: rates.average(:rate),
      total_changes: rates.count,
      significant_changes: rates.significant_changes.count,
      latest_rate: rates.last&.rate
    }
  end

  # Instance methods
  def significant_change?
    change_percentage.present? && change_percentage.abs > 5.0
  end

  def change_direction
    return 'neutral' if change_percentage.nil? || change_percentage == 0
    change_percentage > 0 ? 'up' : 'down'
  end

  def formatted_change_percentage
    return 'N/A' if change_percentage.nil?
    direction = change_percentage > 0 ? '+' : ''
    "#{direction}#{change_percentage}%"
  end

  def formatted_rate
    "ARS $#{rate.to_s.reverse.gsub(/(\d{3})(?=.)/, '\1.').reverse}"
  end
end
