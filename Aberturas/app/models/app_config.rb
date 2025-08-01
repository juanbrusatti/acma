class AppConfig < ApplicationRecord
  validates :key, presence: true, uniqueness: true
  validates :value, presence: true

  # Get the current MEP rate
  def self.current_mep_rate
    config = find_by(key: 'mep_rate')
    config&.value&.to_f || 0.0
  end

  # Set the current MEP rate
  def self.set_mep_rate(rate)
    config = find_or_initialize_by(key: 'mep_rate')
    config.value = rate.to_s
    config.save!
    rate.to_f
  end

  # Check if MEP rate is set
  def self.mep_rate_set?
    current_mep_rate > 0
  end
end
