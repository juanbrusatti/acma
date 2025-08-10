require "test_helper"

class AppConfigTest < ActiveSupport::TestCase
  def setup
    AppConfig.delete_all # Clean up any existing configs
    Supply.delete_all # Clean up any existing supplies to avoid uniqueness conflicts
  end

  test "validates presence of key and value" do
    config = AppConfig.new
    assert_not config.valid?
    assert_includes config.errors[:key], "no puede estar en blanco"
    assert_includes config.errors[:value], "no puede estar en blanco"
  end

  test "validates uniqueness of key" do
    AppConfig.create!(key: "test_key", value: "test_value")
    duplicate = AppConfig.new(key: "test_key", value: "another_value")
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:key], "ya ha sido tomado"
  end

  test "current_mep_rate returns 0.0 when no MEP rate is set" do
    assert_equal 0.0, AppConfig.current_mep_rate
  end

  test "current_mep_rate returns the stored MEP rate" do
    AppConfig.create!(key: "mep_rate", value: "1250.75")
    assert_equal 1250.75, AppConfig.current_mep_rate
  end

  test "set_mep_rate creates new config when none exists" do
    AppConfig.delete_all
    
    AppConfig.set_mep_rate(1200.50)
    
    config = AppConfig.find_by(key: "mep_rate")
    assert_not_nil config
    assert_equal "1200.5", config.value
  end

  test "set_mep_rate updates existing config" do
    AppConfig.create!(key: "mep_rate", value: "1000.0")
    
    rate = AppConfig.set_mep_rate(1500.25)
    
    assert_equal 1500.25, rate
    assert_equal 1500.25, AppConfig.current_mep_rate
    assert_equal 1, AppConfig.where(key: "mep_rate").count
  end

  test "mep_rate_set? returns false when no MEP rate exists" do
    assert_not AppConfig.mep_rate_set?
  end

  test "mep_rate_set? returns true when MEP rate exists" do
    AppConfig.create!(key: "mep_rate", value: "1200.0")
    assert AppConfig.mep_rate_set?
  end

  test "mep_rate_set? returns false when MEP rate is 0" do
    AppConfig.create!(key: "mep_rate", value: "0")
    assert_not AppConfig.mep_rate_set?
  end

  # Tests for innertube pricing calculations
  test "calculate_innertube_price_per_meter calculates price correctly with supplies" do
    # Create supplies needed for calculation
    Supply.create!(name: "Tamiz", price_usd: 5.0, price_peso: 6000.0)
    Supply.create!(name: "Hotmelt", price_usd: 7.0, price_peso: 7000.0)
    Supply.create!(name: "Cinta", price_usd: 5.0, price_peso: 5000.0)
    Supply.create!(name: "Perfil separador", price_usd: 4.0, price_peso: 4000.0)
    
    # Calculate price for 6mm innertube
    price_per_meter = AppConfig.calculate_innertube_price_per_meter(6)
    
    # Should get a positive price based on supplies
    assert price_per_meter > 0, "Should calculate a positive price"
    
    # Verify it uses peso prices directly from supplies
    perfil_price = Supply.find_by(name: "Perfil separador").price_peso
    tamiz_price = Supply.find_by(name: "Tamiz").price_peso
    cinta_price = Supply.find_by(name: "Cinta").price_peso
    hotmelt_price = Supply.find_by(name: "Hotmelt").price_peso
    
    # For 6mm: 1 perfil + 25g tamiz + 2 cinta + 35g hotmelt
    expected_price = perfil_price * 1 + 
                    (tamiz_price * 25) / 1000.0 + 
                    cinta_price * 2 + 
                    (hotmelt_price * 35) / 1000.0
    
    assert_equal expected_price, price_per_meter
  end

  test "calculate_innertube_price_per_meter returns 0_when_supplies_missing" do
    # Delete the required supplies to test missing scenario
    Supply.where(name: ["Tamiz", "Hotmelt", "Cinta", "Perfil separador"]).delete_all
    
    price_per_meter = AppConfig.calculate_innertube_price_per_meter(6)
    assert_equal 0, price_per_meter
  end

  test "calculate_innertube_price_per_meter works for different innertube sizes" do
    # Create supplies needed for calculation
    Supply.create!(name: "Tamiz", price_usd: 5.0, price_peso: 6000.0)
    Supply.create!(name: "Hotmelt", price_usd: 7.0, price_peso: 7000.0)
    Supply.create!(name: "Cinta", price_usd: 5.0, price_peso: 5000.0)
    Supply.create!(name: "Perfil separador", price_usd: 4.0, price_peso: 4000.0)
    
    # Test different sizes
    price_6mm = AppConfig.calculate_innertube_price_per_meter(6)
    price_9mm = AppConfig.calculate_innertube_price_per_meter(9)
    price_12mm = AppConfig.calculate_innertube_price_per_meter(12)
    price_20mm = AppConfig.calculate_innertube_price_per_meter(20)
    
    # All should be positive
    assert price_6mm > 0
    assert price_9mm > 0
    assert price_12mm > 0
    assert price_20mm > 0
    
    # Generally larger sizes should cost more due to more material
    assert price_9mm > price_6mm
    assert price_12mm > price_9mm
    assert price_20mm > price_12mm
  end

  test "calculate_innertube_total_price calculates total price correctly" do
    # Create supplies needed for calculation
    Supply.create!(name: "Tamiz", price_usd: 5.0, price_peso: 6000.0)
    Supply.create!(name: "Hotmelt", price_usd: 7.0, price_peso: 7000.0)
    Supply.create!(name: "Cinta", price_usd: 5.0, price_peso: 5000.0)
    Supply.create!(name: "Perfil separador", price_usd: 4.0, price_peso: 4000.0)
    Supply.create!(name: "Angulos", price_usd: 5.0, price_peso: 6000.0)
    
    # Calculate total price for 2.5 meters of 6mm innertube
    perimeter_meters = 2.5
    total_price = AppConfig.calculate_innertube_total_price(6, perimeter_meters)
    
    # Should be (price_per_meter * perimeter_meters) + (4 angles)
    price_per_meter = AppConfig.calculate_innertube_price_per_meter(6)
    angulo_price = Supply.find_by(name: "Angulos").price_peso
    expected_total = (price_per_meter * perimeter_meters) + (angulo_price * 4)
    
    assert_equal expected_total, total_price
  end

  test "calculate_innertube_total_price includes fixed 4 angles" do
    # Create the Angulos supply needed for calculation
    Supply.create!(name: "Angulos", price_usd: 5.0, price_peso: 6000.0)
    
    # Even for 0 perimeter, should include 4 angles
    total_price = AppConfig.calculate_innertube_total_price(6, 0)
    angulo_price = Supply.find_by(name: "Angulos").price_peso
    expected_total = angulo_price * 4
    
    assert_equal expected_total, total_price
  end

  test "calculate_innertube_total_price handles negative perimeter" do
    # Create supplies needed for calculation
    Supply.create!(name: "Tamiz", price_usd: 5.0, price_peso: 6000.0)
    Supply.create!(name: "Hotmelt", price_usd: 7.0, price_peso: 7000.0)
    Supply.create!(name: "Cinta", price_usd: 5.0, price_peso: 5000.0)
    Supply.create!(name: "Perfil separador", price_usd: 4.0, price_peso: 4000.0)
    Supply.create!(name: "Angulos", price_usd: 5.0, price_peso: 6000.0)
    
    # For negative perimeter, linear cost should be 0 but angles still included
    total_price = AppConfig.calculate_innertube_total_price(6, -1.5)
    angulo_price = Supply.find_by(name: "Angulos").price_peso
    
    # Linear cost is negative but still calculated
    price_per_meter = AppConfig.calculate_innertube_price_per_meter(6)
    expected_total = (price_per_meter * -1.5) + (angulo_price * 4)
    
    assert_equal expected_total, total_price
  end
end
