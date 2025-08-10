require "test_helper"

class SuppliesHelperTest < ActionView::TestCase
  include SuppliesHelper

  def setup
    @supply_with_price = Supply.new(name: "Test Supply", price_usd: 25.50)
    @supply_without_price = Supply.new(name: "Test Supply", price_usd: nil)
    @supply_zero_price = Supply.new(name: "Test Supply", price_usd: 0)
  end

  test "format_supply_price should format valid price" do
    result = format_supply_price(@supply_with_price)
    assert_equal "US$25.50", result
  end

  test "format_supply_price should handle nil price" do
    result = format_supply_price(@supply_without_price)
    assert_equal "N/A", result
  end

  test "format_supply_price should handle zero price" do
    result = format_supply_price(@supply_zero_price)
    assert_equal "N/A", result
  end

  test "supply_price_class should return green for valid price" do
    result = supply_price_class(@supply_with_price)
    assert_equal "font-semibold text-green-700", result
  end

  test "supply_price_class should return gray for invalid price" do
    result = supply_price_class(@supply_without_price)
    assert_equal "font-semibold text-gray-500", result
  end

  test "supply_has_price? should return true for valid price" do
    assert supply_has_price?(@supply_with_price)
  end

  test "supply_has_price? should return false for invalid price" do
    assert_not supply_has_price?(@supply_without_price)
    assert_not supply_has_price?(@supply_zero_price)
  end
end
