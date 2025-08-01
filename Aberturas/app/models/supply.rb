class Supply < ApplicationRecord
  BASICS = ["Tamiz", "Hotmelt", "Cinta"]

  # Validations
  validates :name, presence: true, uniqueness: true
  validates :price_usd, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :price_peso, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  # Callbacks
  before_save :calculate_peso_price_if_needed

  # Class methods
  def self.basics
    BASICS.map do |name|
      find_or_create_by(name: name)
    end
  end

  # Instance methods
  def calculate_peso_price_from_usd(mep_rate)
    return 0.0 if price_usd.nil? || mep_rate.nil? || mep_rate <= 0
    
    price_usd * mep_rate
  end

  def update_peso_price_from_usd!(mep_rate)
    new_peso_price = calculate_peso_price_from_usd(mep_rate)
    update!(price_peso: new_peso_price)
  end

  private

  # Automatically calculate peso price when USD price changes
  def calculate_peso_price_if_needed
    if price_usd_changed? && price_usd.present? && AppConfig.mep_rate_set?
      self.price_peso = calculate_peso_price_from_usd(AppConfig.current_mep_rate)
    end
  end
end
