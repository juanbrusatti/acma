require "test_helper"

class SuppliesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @supply = supplies(:tamiz)
  end

  # test "should get index" do
  #   get supplies_url
  #   assert_response :success
  # end

  test "should get new" do
    get new_supply_url
    assert_response :success
  end

  test "should create supply" do
    assert_difference("Supply.count") do
      post supplies_url, params: { supply: { name: "New Supply", price_usd: 25.0 } }
    end

    assert_redirected_to supply_url(Supply.last)
  end

  # test "should show supply" do
  #   get supply_url(@supply)
  #   assert_response :success
  # end

  test "should get edit" do
    get edit_supply_url(@supply)
    assert_response :success
  end

  test "should update supply" do
    patch supply_url(@supply), params: { supply: { name: @supply.name, price_usd: @supply.price_usd } }
    assert_redirected_to glass_prices_path
  end

  test "should destroy supply" do
    assert_difference("Supply.count", -1) do
      delete supply_url(@supply)
    end

    assert_redirected_to supplies_url
  end
end
