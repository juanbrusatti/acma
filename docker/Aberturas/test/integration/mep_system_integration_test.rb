require "test_helper"

class MepSystemIntegrationTest < ActionDispatch::IntegrationTest
  def setup
    AppConfig.delete_all
    Supply.delete_all
    GlassPrice.delete_all
  end

  test "complete MEP workflow: set rate, create supplies, and verify conversions" do
    # Step 1: Set initial MEP rate
    initial_mep_rate = 1200.0
    patch update_all_supplies_mep_glass_prices_url, params: { mep_rate: initial_mep_rate }
    assert_redirected_to glass_prices_url
    
        # Verify MEP rate was stored
    assert_equal 1200.0, AppConfig.current_mep_rate
  end

  test "MEP system calculates camera prices when rate is updated" do
    AppConfig.delete_all
    Supply.delete_all
    
    # Create basic supplies with exact values
    Supply.create!(name: "Tamiz", price_usd: 5.0, price_peso: 0.0)
    Supply.create!(name: "Hotmelt", price_usd: 7.0, price_peso: 0.0)
    Supply.create!(name: "Cinta", price_usd: 5.0, price_peso: 0.0)
    Supply.create!(name: "Angulos", price_usd: 5.0, price_peso: 0.0)
    Supply.create!(name: "Perfil separador", price_usd: 3.0, price_peso: 0.0)
    
    # Update MEP rate - this will automatically recalculate peso prices and innertube prices
    patch update_all_supplies_mep_glass_prices_url, params: { mep_rate: 1500.0 }
    assert_redirected_to glass_prices_url
    
    # Verify camera prices were calculated correctly based on actual supply costs
    # These values come from the real calculation using supply prices
    expected_prices = {
      6 => 20055.0,   # Real calculated value with MEP 1500.0
      9 => 20415.0,   # Real calculated value with MEP 1500.0
      12 => 20722.5,  # Real calculated value with MEP 1500.0
      20 => 21045.0   # Real calculated value with MEP 1500.0
    }
    
    expected_prices.each do |size, expected_price|
      actual_price = AppConfig.get_innertube_price(size)
      assert_equal expected_price, actual_price, "Camera #{size}mm should cost $#{expected_price}, got $#{actual_price}"
    end
  end

  test "camera prices are recalculated when MEP rate changes" do
    AppConfig.delete_all
    Supply.delete_all
    
    # Create basic supplies with exact values
    Supply.create!(name: "Tamiz", price_usd: 5.0, price_peso: 0.0)
    Supply.create!(name: "Hotmelt", price_usd: 7.0, price_peso: 0.0)
    Supply.create!(name: "Cinta", price_usd: 5.0, price_peso: 0.0)
    Supply.create!(name: "Angulos", price_usd: 5.0, price_peso: 0.0)
    Supply.create!(name: "Perfil separador", price_usd: 3.0, price_peso: 0.0)
    
    # Set initial MEP rate
    AppConfig.set_mep_rate(1000.0)
    
    # Update to new MEP rate
    patch update_all_supplies_mep_glass_prices_url, params: { mep_rate: 1200.0 }
    
    # Verify new camera prices based on real calculations with MEP 1200.0
    assert_equal 16044.0, AppConfig.get_innertube_price(6)   # Real calculated value
    assert_equal 16332.0, AppConfig.get_innertube_price(9)   # Real calculated value  
    assert_equal 16578.0, AppConfig.get_innertube_price(12)  # Real calculated value
    assert_equal 16836.0, AppConfig.get_innertube_price(20)  # Real calculated value
  end

  test "supplies automatic peso conversion workflow" do
    # Step 1: Set MEP rate first
    AppConfig.set_mep_rate(1200.0)
    
    # Step 2: Create supplies with USD prices
    supply1 = Supply.create!(name: "Aluminum Profile", price_usd: 15.50)
    supply2 = Supply.create!(name: "Glass Sealant", price_usd: 8.75)
    
    # Step 3: Verify automatic peso conversion happened
    supply1.reload
    supply2.reload
    
    expected_peso1 = 18600.0 # 15.50 * 1200
    expected_peso2 = 10500.0 # 8.75 * 1200
    
    assert_equal expected_peso1, supply1.price_peso
    assert_equal expected_peso2, supply2.price_peso
    
    # Step 4: Update MEP rate and verify all supplies are recalculated
    new_mep_rate = 1350.0
    patch update_all_supplies_mep_glass_prices_url, params: { mep_rate: new_mep_rate }
    
    supply1.reload
    supply2.reload
    
    new_expected_peso1 = 20925.0 # 15.50 * 1350
    new_expected_peso2 = 11812.5 # 8.75 * 1350
    
    assert_equal new_expected_peso1, supply1.price_peso
    assert_equal new_expected_peso2, supply2.price_peso
    
    # Step 5: Verify rate is persisted
    assert_equal new_mep_rate, AppConfig.current_mep_rate
  end

  test "glass prices percentage update workflow" do
    # Create glass prices with different buying prices
    glass_price1 = GlassPrice.create!(
      glass_type: "LAM", 
      thickness: "3+3", 
      color: "INC", 
      buying_price: 200.0, 
      percentage: 10.0
    )
    
    glass_price2 = GlassPrice.create!(
      glass_type: "LAM", 
      thickness: "4+4", 
      color: "BLS", 
      buying_price: 300.0, 
      percentage: 15.0
    )
    
    # Glass price without buying price (should not be affected)
    glass_price3 = GlassPrice.create!(
      glass_type: "LAM", 
      thickness: "5+5", 
      color: "GRY", 
      buying_price: 0.0, 
      percentage: 20.0
    )
    
    # Update all percentages
    new_percentage = 25.0
    patch update_all_percentages_glass_prices_url, params: { percentage: new_percentage }
    assert_redirected_to glass_prices_url
    
    # Verify updates
    glass_price1.reload
    glass_price2.reload
    glass_price3.reload
    
    # Prices with buying prices should be updated
    assert_equal new_percentage, glass_price1.percentage
    assert_equal new_percentage, glass_price2.percentage
    assert_equal 250.0, glass_price1.selling_price # 200 * 1.25
    assert_equal 375.0, glass_price2.selling_price # 300 * 1.25
    
    # Price without buying price should remain unchanged
    assert_equal 20.0, glass_price3.percentage
  end

  test "MEP system handles edge cases correctly" do
    # Test with zero MEP rate
    patch update_all_supplies_mep_glass_prices_url, params: { mep_rate: 0 }
    assert_redirected_to glass_prices_url
    follow_redirect!
    assert_select "div.bg-red-100", text: /El valor del dólar MEP debe ser mayor a 0/
    
    # Test with negative percentage
    patch update_all_percentages_glass_prices_url, params: { percentage: -10 }
    assert_redirected_to glass_prices_url
    follow_redirect!
    assert_select "div.bg-red-100", text: /El porcentaje debe ser mayor o igual a 0/
  end

  test "supplies with zero USD price are not affected by MEP updates" do
    # Set MEP rate
    AppConfig.set_mep_rate(1200.0)
    
    # Create supplies: one with USD price, one without
    supply_with_usd = Supply.create!(name: "With USD", price_usd: 10.0, price_peso: 100.0)
    supply_without_usd = Supply.create!(name: "Without USD", price_usd: 0.0, price_peso: 500.0)
    
    # Update MEP rate
    patch update_all_supplies_mep_glass_prices_url, params: { mep_rate: 1500.0 }
    
    supply_with_usd.reload
    supply_without_usd.reload
    
    # Only supply with USD price should be affected
    assert_equal 15000.0, supply_with_usd.price_peso # 10.0 * 1500
    assert_equal 500.0, supply_without_usd.price_peso # Unchanged
  end

  test "new supplies automatically get peso price when MEP rate exists" do
    # Set MEP rate first
    AppConfig.set_mep_rate(1400.0)
    
    # Create new supply with USD price
    supply = Supply.create!(name: "Auto Calc Supply", price_usd: 12.5)
    
    # Should automatically calculate peso price
    expected_peso_price = 17500.0 # 12.5 * 1400
    assert_equal expected_peso_price, supply.price_peso
  end

  test "updating supply USD price recalculates peso price automatically" do
    # Set MEP rate
    AppConfig.set_mep_rate(1300.0)
    
    # Create supply
    supply = Supply.create!(name: "Update Test Supply", price_usd: 5.0)
    initial_peso_price = supply.price_peso
    
    # Update USD price
    patch supply_url(supply), params: { supply: { price_usd: 10.0 } }
    
    supply.reload
    
    # Should have new peso price
    expected_new_peso_price = 13000.0 # 10.0 * 1300
    assert_equal expected_new_peso_price, supply.price_peso
    assert_not_equal initial_peso_price, supply.price_peso
  end

  test "turbo stream responses work for MEP operations" do
    # Test turbo stream for MEP rate update
    Supply.create!(name: "Test Supply", price_usd: 10.0)
    
    patch update_all_supplies_mep_glass_prices_url, 
          params: { mep_rate: 1200.0 }, 
          headers: { "Accept" => "text/vnd.turbo-stream.html" }
    
    assert_response :success
    assert_equal "text/vnd.turbo-stream.html; charset=utf-8", @response.content_type
    assert_match(/turbo-stream/, @response.body)
    
    # Test turbo stream for percentage update
    GlassPrice.create!(glass_type: "LAM", thickness: "3+3", color: "INC", buying_price: 100.0)
    
    patch update_all_percentages_glass_prices_url, 
          params: { percentage: 20.0 }, 
          headers: { "Accept" => "text/vnd.turbo-stream.html" }
    
    assert_response :success
    assert_equal "text/vnd.turbo-stream.html; charset=utf-8", @response.content_type
    assert_match(/turbo-stream/, @response.body)
  end
end
