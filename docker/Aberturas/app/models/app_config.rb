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

  # Get the official rate for pricing calculations (yesterday's rate)
  def self.current_official_rate_for_pricing
    # Usar la cotización del día anterior para calcular precios de hoy
    yesterday_rate = OfficialRateHistory.yesterday_rate
    
    if yesterday_rate && yesterday_rate > 0
      yesterday_rate
    else
      # Fallback al MEP rate actual si no hay cotización oficial del día anterior
      current_mep_rate
    end
  end

  # Get today's official rate (for tomorrow's pricing)
  def self.current_official_rate_today
    OfficialRateHistory.today_rate || current_mep_rate
  end

  # Check if official rate system is active
  def self.official_rate_system_active?
    OfficialRateHistory.exists?
  end

  # Innertube (air chamber) prices methods
  def self.get_innertube_price(size)
    config = find_by(key: "innertube_price_#{size}")
    config&.value&.to_f || 0.0
  end

  def self.set_innertube_price(size, price)
    config = find_or_initialize_by(key: "innertube_price_#{size}")
    config.value = price.to_s
    config.save!
    price.to_f
  end

  def self.get_all_innertube_prices
    {
      6 => get_innertube_price(6),
      9 => get_innertube_price(9),
      12 => get_innertube_price(12),
      20 => get_innertube_price(20)
    }
  end

  def self.set_all_innertube_prices(prices_hash)
    prices_hash.each do |size, price|
      set_innertube_price(size, price)
    end
  end

    # Calculate innertube (air chamber) price per linear meter based on supplies
  def self.calculate_innertube_price_per_meter(size)
    # Innertube specifications based on Fenzi documentation
    innertube_specs = {
      6 => {
        perfil_separador: 1,    # 1 per linear meter
        tamiz_molecular: 25,    # grams per linear meter (estimated for 6mm)
        biadhesivo: 2,          # linear meters per linear meter
        sellador_thiover: 35    # grams per linear meter (estimated for 6mm)
        # NOTE: angulos are calculated separately - always 4 per DVH
      },
      9 => {
        perfil_separador: 1,    # 1 per linear meter
        tamiz_molecular: 45,    # grams per linear meter (from Fenzi doc)
        biadhesivo: 2,          # linear meters per linear meter
        sellador_thiover: 55    # grams per linear meter (from Fenzi doc)
        # NOTE: angulos are calculated separately - always 4 per DVH
      },
      12 => {
        perfil_separador: 1,    # 1 per linear meter
        tamiz_molecular: 65,    # grams per linear meter (from Fenzi doc)
        biadhesivo: 2,          # linear meters per linear meter
        sellador_thiover: 70    # grams per linear meter (from Fenzi doc)
        # NOTE: angulos are calculated separately - always 4 per DVH
      },
      20 => {
        perfil_separador: 1,    # 1 per linear meter
        tamiz_molecular: 80,    # grams per linear meter (estimated for 20mm)
        biadhesivo: 2,          # linear meters per linear meter
        sellador_thiover: 90    # grams per linear meter (estimated for 20mm)
        # NOTE: angulos are calculated separately - always 4 per DVH
      }
    }

    specs = innertube_specs[size]
    return 0.0 unless specs

    total_price = 0.0

    # Get supply prices (peso prices per unit)
    perfil_price = Supply.find_by(name: 'Perfil separador')&.price_peso || 0.0
    tamiz_price = Supply.find_by(name: 'Tamiz')&.price_peso || 0.0        # per kg
    cinta_price = Supply.find_by(name: 'Cinta')&.price_peso || 0.0
    hotmelt_price = Supply.find_by(name: 'Hotmelt')&.price_peso || 0.0    # per kg

    # Calculate price per linear meter (excluding angles - they're calculated separately)
    total_price += perfil_price * specs[:perfil_separador]
    total_price += (tamiz_price * specs[:tamiz_molecular]) / 1000.0  # Convert grams to kg
    total_price += cinta_price * specs[:biadhesivo]
    total_price += (hotmelt_price * specs[:sellador_thiover]) / 1000.0  # Convert grams to kg

    total_price
  end

  # Calculate total innertube price for a specific DVH (includes fixed 4 angles)
  def self.calculate_innertube_total_price(size, perimeter_meters)
    # Get price per linear meter (without angles)
    price_per_meter = calculate_innertube_price_per_meter(size)
    linear_cost = price_per_meter * perimeter_meters
    
    # Add fixed cost of 4 angles per DVH
    angulo_price = Supply.find_by(name: 'Angulos')&.price_peso || 0.0
    angles_cost = angulo_price * 4  # Always 4 angles per DVH
    
    linear_cost + angles_cost
  end

  # Calculate and update all innertube prices
  def self.update_all_innertube_prices
    [6, 9, 12, 20].each do |size|
      price = calculate_innertube_price_per_meter(size)
      set_innertube_price(size, price)
    end
  end
end