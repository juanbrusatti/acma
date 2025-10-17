# test/controllers/glass_prices_controller_test.rb
require 'test_helper'

class GlassPricesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @glass_price = glass_prices(:one)
    gp = glass_prices(:one)
    @glass_price_params = {
      glass_type: gp.glass_type,
      thickness: gp.thickness,
      color: gp.color,
      buying_price: gp.buying_price,
      percentage: gp.percentage,
      selling_price: gp.selling_price
    }
  end

  test "should get index" do
    get glass_prices_url
    assert_response :success
  end

  test "should create glass_price" do
    assert_difference('GlassPrice.count') do
      post glass_prices_url, params: { glass_price: @glass_price_params }
    end
    assert_redirected_to glass_price_url(GlassPrice.last)
  end

  test "should get edit" do
    get edit_glass_price_url(@glass_price)
    assert_response :success
  end

  test "should update glass_price" do
    patch glass_price_url(@glass_price), params: { glass_price: { percentage: 60.0 } }
    @glass_price.reload
    assert_equal 60.0, @glass_price.percentage
    assert_redirected_to glass_prices_url
  end

  test "should destroy glass_price" do
    assert_difference('GlassPrice.count', -1) do
      delete glass_price_url(@glass_price)
    end
    assert_redirected_to glass_prices_url
  end

  test "should update all percentages" do
    glass_prices = [glass_prices(:one), glass_prices(:two)]
    glass_prices.each { |gp| gp.update!(buying_price: 100.0, percentage: 50.0, selling_price: 150.0) }

    patch update_all_percentages_glass_prices_url, params: { percentage: 60.0 }, as: :turbo_stream

    assert_equal 60.0, glass_prices.first.reload.percentage
    assert_in_delta 160.0, glass_prices.first.reload.selling_price, 0.0001
  end
end
