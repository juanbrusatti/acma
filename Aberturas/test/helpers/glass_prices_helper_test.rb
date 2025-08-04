require "test_helper"

class GlassPricesHelperTest < ActionView::TestCase
  include GlassPricesHelper

  def setup
    AppConfig.delete_all
  end

  test "format_innertube_price returns correct format for valid price" do
    AppConfig.set_innertube_price(6, 14400.0)
    result = format_innertube_price(6)
    assert_equal "$14,400.00", result
  end

  test "format_innertube_price returns No establecido for zero price" do
    result = format_innertube_price(9) # No price set, returns 0.0
    assert_equal "No establecido", result
  end

  test "formatted_innertube_prices returns hash with formatted prices" do
    AppConfig.set_innertube_price(6, 12000.0)
    AppConfig.set_innertube_price(12, 18000.0)

    result = formatted_innertube_prices

    assert_equal "$12,000.00", result[6]
    assert_equal "No establecido", result[9]
    assert_equal "$18,000.00", result[12]
    assert_equal "No establecido", result[20]
  end

  test "format_glass_price returns correct format" do
    result = format_glass_price(125.50)
    assert_equal "$125.50", result
  end

  test "format_glass_price returns No establecido for nil or zero" do
    assert_equal "No establecido", format_glass_price(nil)
    assert_equal "No establecido", format_glass_price(0)
  end

  test "calculate_selling_price calculates correctly" do
    result = calculate_selling_price(100.0, 25.0)
    assert_equal 125.0, result
  end

  test "calculate_selling_price returns 0 for blank values" do
    assert_equal 0, calculate_selling_price(nil, 25.0)
    assert_equal 0, calculate_selling_price(100.0, nil)
  end
end
