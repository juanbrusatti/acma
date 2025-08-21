require "test_helper"

class CurrencyHelperTest < ActionView::TestCase
  include CurrencyHelper

  test "should format argentine currency correctly" do
    # Casos básicos
    assert_equal "$150,00", format_argentine_currency(150.00, unit: "$", precision: 2)
    assert_equal "$1.250,50", format_argentine_currency(1250.50, unit: "$", precision: 2)
    assert_equal "$1.234.567,89", format_argentine_currency(1234567.89, unit: "$", precision: 2)
    assert_equal "$0,00", format_argentine_currency(0, unit: "$", precision: 2)
    
    # Con diferentes unidades
    assert_equal "US$150,00", format_argentine_currency(150.00, unit: "US$", precision: 2)
    assert_equal "€150,00", format_argentine_currency(150.00, unit: "€", precision: 2)
    
    # Con diferentes precisiones
    assert_equal "$150,0", format_argentine_currency(150.00, unit: "$", precision: 1)
    assert_equal "$150,000", format_argentine_currency(150.00, unit: "$", precision: 3)
  end

  test "should handle edge cases" do
    # Valores nil o vacíos
    assert_equal "N/A", format_argentine_currency(nil, unit: "$", precision: 2)
    assert_equal "N/A", format_argentine_currency("", unit: "$", precision: 2)
    assert_equal "N/A", format_argentine_currency(0, unit: "$", precision: 2)
    
    # Valores negativos
    assert_equal "$-150,00", format_argentine_currency(-150.00, unit: "$", precision: 2)
    assert_equal "$-1.250,50", format_argentine_currency(-1250.50, unit: "$", precision: 2)
  end

  test "should format numbers without currency symbol" do
    assert_equal "150,00", format_number_argentine(150.00, precision: 2)
    assert_equal "1.250,50", format_number_argentine(1250.50, precision: 2)
    assert_equal "1.234.567,89", format_number_argentine(1234567.89, precision: 2)
    assert_equal "0,00", format_number_argentine(0, precision: 2)
    assert_equal "N/A", format_number_argentine(nil, precision: 2)
  end

  test "should use format_price alias" do
    assert_equal "$150,00", format_price(150.00, unit: "$", precision: 2)
    assert_equal "$1.250,50", format_price(1250.50, unit: "$", precision: 2)
  end
end
