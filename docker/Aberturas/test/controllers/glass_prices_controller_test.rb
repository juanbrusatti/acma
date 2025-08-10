require "test_helper"

class GlassPricesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @glass_price = glass_prices(:one)
  end

  test "should get index" do
    get glass_prices_url
    assert_response :success
  end

  # test "should get new" do
  #   get new_glass_price_url
  #   assert_response :success
  # end

  test "should create glass_price" do
    assert_difference("GlassPrice.count") do
      post glass_prices_url, params: { glass_price: { glass_type: @glass_price.glass_type, thickness: @glass_price.thickness, color: @glass_price.color, buying_price: @glass_price.buying_price, selling_price: @glass_price.selling_price, percentage: @glass_price.percentage } }
    end

    assert_redirected_to glass_price_url(GlassPrice.last)
  end

  # test "should show glass_price" do
  #   get glass_price_url(@glass_price)
  #   assert_response :success
  # end

  test "should get edit" do
    get edit_glass_price_url(@glass_price)
    assert_response :success
  end

  test "should update glass_price" do
    patch glass_price_url(@glass_price), params: { glass_price: { glass_type: @glass_price.glass_type, thickness: @glass_price.thickness, color: @glass_price.color, buying_price: @glass_price.buying_price, selling_price: @glass_price.selling_price, percentage: @glass_price.percentage } }
    assert_redirected_to glass_prices_url
  end

  test "should destroy glass_price" do
    assert_difference("GlassPrice.count", -1) do
      delete glass_price_url(@glass_price)
    end

    assert_redirected_to glass_prices_url
  end

  # MEP Dollar System Tests
  test "should update all percentages successfully" do
    # Create some glass prices with buying prices
    glass_price1 = GlassPrice.create!(glass_type: "LAM", thickness: "3+3", color: "INC", buying_price: 100.0, percentage: 10.0)
    glass_price2 = GlassPrice.create!(glass_type: "LAM", thickness: "4+4", color: "BLS", buying_price: 150.0, percentage: 15.0)
    
    new_percentage = 25.0
    
    patch update_all_percentages_glass_prices_url, params: { percentage: new_percentage }
    assert_redirected_to glass_prices_url
    assert_match(/Porcentaje general actualizado correctamente/, flash[:notice])
    
    # Verify percentages were updated
    glass_price1.reload
    glass_price2.reload
    
    assert_equal new_percentage, glass_price1.percentage
    assert_equal new_percentage, glass_price2.percentage
    
    # Verify selling prices were recalculated
    assert_equal 125.0, glass_price1.selling_price # 100 * 1.25
    assert_equal 187.5, glass_price2.selling_price # 150 * 1.25
  end

  test "should handle negative percentage in update_all_percentages" do
    patch update_all_percentages_glass_prices_url, params: { percentage: -5.0 }
    assert_redirected_to glass_prices_url
    assert_match(/El porcentaje debe ser mayor o igual a 0/, flash[:alert])
  end

  test "should update all supplies MEP successfully" do
    # Clean up any existing configs
    AppConfig.delete_all
    
    # Create supplies with USD prices
    supply1 = Supply.create!(name: "Test Supply 1", price_usd: 10.0, price_peso: 0.0)
    supply2 = Supply.create!(name: "Test Supply 2", price_usd: 25.0, price_peso: 0.0)
    
    mep_rate = 1200.0
    
    patch update_all_supplies_mep_glass_prices_url, params: { mep_rate: mep_rate }
    assert_redirected_to glass_prices_url
    assert_match(/Dólar MEP actualizado correctamente/, flash[:notice])
    
    # Verify MEP rate was stored
    assert_equal mep_rate, AppConfig.current_mep_rate
    
    # Verify supplies were updated
    supply1.reload
    supply2.reload
    
    assert_equal 12000.0, supply1.price_peso # 10.0 * 1200
    assert_equal 30000.0, supply2.price_peso # 25.0 * 1200
  end

  test "should calculate and save camera prices during MEP update" do
    AppConfig.delete_all
    Supply.delete_all
    
    # Ensure basic supplies exist with the required prices and clear peso prices
    tamiz = Supply.create!(name: "Tamiz", price_usd: 5.0, price_peso: 0.0)
    hotmelt = Supply.create!(name: "Hotmelt", price_usd: 7.0, price_peso: 0.0)
    cinta = Supply.create!(name: "Cinta", price_usd: 5.0, price_peso: 0.0)
    angulos = Supply.create!(name: "Angulos", price_usd: 5.0, price_peso: 0.0)
    perfil = Supply.create!(name: "Perfil separador", price_usd: 3.0, price_peso: 0.0)
    
    mep_rate = 1200.0
    
    patch update_all_supplies_mep_glass_prices_url, params: { mep_rate: mep_rate }
    assert_redirected_to glass_prices_url
    
    # Verify camera prices were calculated and saved using real calculated values
    expected_camera_prices = {
      6 => 16044.0,   # Real calculated value with MEP 1200.0
      9 => 16332.0,   # Real calculated value with MEP 1200.0
      12 => 16578.0,  # Real calculated value with MEP 1200.0
      20 => 16836.0   # Real calculated value with MEP 1200.0
    }
    
    expected_camera_prices.each do |size, expected_price|
      assert_equal expected_price, AppConfig.get_innertube_price(size), "Camera #{size}mm price should be #{expected_price}"
    end
  end

  test "should handle zero or negative MEP rate in update_all_supplies_mep" do
    patch update_all_supplies_mep_glass_prices_url, params: { mep_rate: 0 }
    assert_redirected_to glass_prices_url
    assert_match(/El valor del dólar MEP debe ser mayor a 0/, flash[:alert])
    
    patch update_all_supplies_mep_glass_prices_url, params: { mep_rate: -100 }
    assert_redirected_to glass_prices_url
    assert_match(/El valor del dólar MEP debe ser mayor a 0/, flash[:alert])
  end

  test "should update percentages with turbo_stream format" do
    GlassPrice.create!(glass_type: "LAM", thickness: "3+3", color: "INC", buying_price: 100.0, percentage: 10.0)
    
    patch update_all_percentages_glass_prices_url, params: { percentage: 20.0 }, as: :turbo_stream
    assert_response :success
    assert_match(/turbo-stream/, @response.content_type)
  end

  test "should update MEP with turbo_stream format" do
    AppConfig.delete_all
    Supply.create!(name: "Test Supply", price_usd: 10.0, price_peso: 0.0)
    
    patch update_all_supplies_mep_glass_prices_url, params: { mep_rate: 1300.0 }, as: :turbo_stream
    assert_response :success
    assert_match(/turbo-stream/, @response.content_type)
  end

  test "should not update supplies without USD prices in MEP update" do
    AppConfig.delete_all
    
    # Create supplies: one with USD price, one without
    supply_with_usd = Supply.create!(name: "With USD", price_usd: 10.0, price_peso: 0.0)
    supply_without_usd = Supply.create!(name: "Without USD", price_usd: 0.0, price_peso: 100.0)
    
    patch update_all_supplies_mep_glass_prices_url, params: { mep_rate: 1200.0 }
    
    supply_with_usd.reload
    supply_without_usd.reload
    
    # Only the supply with USD price should be updated
    assert_equal 12000.0, supply_with_usd.price_peso
    assert_equal 100.0, supply_without_usd.price_peso # Should remain unchanged
  end

  test "should not update glass prices without buying prices in percentage update" do
    # Create glass prices: one with buying price, one without
    glass_price_with_buying = GlassPrice.create!(glass_type: "LAM", thickness: "3+3", color: "INC", buying_price: 100.0, percentage: 10.0)
    glass_price_without_buying = GlassPrice.create!(glass_type: "LAM", thickness: "4+4", color: "BLS", buying_price: 0.0, percentage: 15.0)
    
    patch update_all_percentages_glass_prices_url, params: { percentage: 25.0 }
    
    glass_price_with_buying.reload
    glass_price_without_buying.reload
    
    # Only the glass price with buying price should be updated
    assert_equal 25.0, glass_price_with_buying.percentage
    assert_equal 15.0, glass_price_without_buying.percentage # Should remain unchanged
  end
end
