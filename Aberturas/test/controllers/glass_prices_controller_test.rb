require "test_helper"

class GlassPricesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @glass_price = glass_prices(:one)
  end

  test "should get index" do
    get glass_prices_url
    assert_response :success
  end

  test "should get new" do
    get new_glass_price_url
    assert_response :success
  end

  test "should create glass_price" do
    assert_difference("GlassPrice.count") do
      post glass_prices_url, params: { glass_price: { glass_type: @glass_price.glass_type, thickness: @glass_price.thickness, color: @glass_price.color, buying_price: @glass_price.buying_price, selling_price: @glass_price.selling_price, percentage: @glass_price.percentage } }
    end

    assert_redirected_to glass_price_url(GlassPrice.last)
  end

  test "should show glass_price" do
    get glass_price_url(@glass_price)
    assert_response :success
  end

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
end
