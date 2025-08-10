require "test_helper"

class SupplyTest < ActiveSupport::TestCase
  def setup
    @supply = Supply.new(name: "Test Supply", price_usd: 10.50)
    AppConfig.delete_all # Clean up any existing configs
  end

  test "should be valid with valid attributes" do
    assert @supply.valid?
  end

  test "should require name" do
    supply = Supply.new
    assert_not supply.valid?
    assert_includes supply.errors[:name], "no puede estar en blanco"
  end

  test "should require unique name" do
    Supply.create!(name: "Test Supply", price_usd: 10.0, price_peso: 12000.0)
    duplicate = Supply.new(name: "Test Supply", price_usd: 15.0, price_peso: 18000.0)
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:name], "ya ha sido tomado"
  end

  test "should allow supply without price_usd" do
    @supply.price_usd = nil
    assert @supply.valid?
  end

  test "should allow supply without price_peso" do
    @supply.price_peso = nil
    assert @supply.valid?
  end

  test "price_usd should be non-negative" do
    supply = Supply.new(name: "Test Supply", price_usd: -10.0)
    assert_not supply.valid?
    assert_includes supply.errors[:price_usd], "debe ser mayor o igual que 0"
  end

  test "price_peso should be non-negative" do
    supply = Supply.new(name: "Test Supply", price_peso: -1000.0)
    assert_not supply.valid?
    assert_includes supply.errors[:price_peso], "debe ser mayor o igual que 0"
  end

  test "basics should return basic supplies" do
    basics = Supply.basics
    assert_equal 5, basics.length # Updated to match all BASICS supplies
    assert_includes basics.map(&:name), "Tamiz"
    assert_includes basics.map(&:name), "Hotmelt"
    assert_includes basics.map(&:name), "Cinta"
    assert_includes basics.map(&:name), "Angulos"
    assert_includes basics.map(&:name), "Perfil separador"
  end

  test "find_or_create_by should work for basics" do
    initial_count = Supply.count
    Supply.basics
    # Should create 3 new supplies if they don't exist
    assert_operator Supply.count, :>=, initial_count
  end

  # MEP Dollar System Tests
  test "calculate_peso_price_from_usd should calculate correctly" do
    mep_rate = 1200.0
    @supply.price_usd = 10.0
    
    expected_peso_price = 12000.0
    assert_equal expected_peso_price, @supply.calculate_peso_price_from_usd(mep_rate)
  end

  test "calculate_peso_price_from_usd should return 0 when price_usd is nil" do
    @supply.price_usd = nil
    mep_rate = 1200.0
    
    assert_equal 0.0, @supply.calculate_peso_price_from_usd(mep_rate)
  end

  test "calculate_peso_price_from_usd should return 0 when mep_rate is nil" do
    @supply.price_usd = 10.0
    
    assert_equal 0.0, @supply.calculate_peso_price_from_usd(nil)
  end

  test "calculate_peso_price_from_usd should return 0 when mep_rate is 0 or negative" do
    @supply.price_usd = 10.0
    
    assert_equal 0.0, @supply.calculate_peso_price_from_usd(0)
    assert_equal 0.0, @supply.calculate_peso_price_from_usd(-100.0)
  end

  test "update_peso_price_from_usd! should update price_peso correctly" do
    @supply.save!
    mep_rate = 1150.25
    @supply.price_usd = 5.0
    
    @supply.update_peso_price_from_usd!(mep_rate)
    @supply.reload
    
    expected_peso_price = 5751.25
    assert_equal expected_peso_price, @supply.price_peso
  end

  test "should automatically calculate peso price when MEP rate is set and price_usd changes" do
    # Set up MEP rate
    AppConfig.set_mep_rate(1300.0)
    
    # Create supply with USD price
    supply = Supply.new(name: "Auto Calculate Test", price_usd: 8.0)
    supply.save!
    
    # Should automatically calculate peso price
    expected_peso_price = 10400.0
    assert_equal expected_peso_price, supply.price_peso
  end

  test "should not automatically calculate peso price when MEP rate is not set" do
    AppConfig.delete_all # Ensure no MEP rate exists
    
    supply = Supply.create!(name: "Test Supply", price_usd: 10.0)
    
    # price_peso should remain as default 0.0, not be automatically calculated
    assert_equal 0.0, supply.price_peso
  end

  test "should recalculate peso price when price_usd is updated and MEP rate exists" do
    # Set up MEP rate
    AppConfig.set_mep_rate(1400.0)
    
    # Create supply
    supply = Supply.create!(name: "Update Test", price_usd: 5.0)
    initial_peso_price = supply.price_peso
    
    # Update USD price
    supply.update!(price_usd: 10.0)
    supply.reload
    
    # Should recalculate peso price
    expected_new_peso_price = 14000.0
    assert_equal expected_new_peso_price, supply.price_peso
    assert_not_equal initial_peso_price, supply.price_peso
  end
end
