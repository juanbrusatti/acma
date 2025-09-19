#!/usr/bin/env ruby

# Test simple para GlassPricesHelper sin dependencias de Rails
require 'minitest/autorun'

# Simular las funciones de Rails que necesitamos
module ActionView
  module Helpers
    module NumberHelper
      def number_with_precision(number, options = {})
        precision = options[:precision] || 2
        separator = options[:separator] || '.'
        delimiter = options[:delimiter] || ','
        
        # Formatear el número
        formatted = sprintf("%.#{precision}f", number.to_f)
        
        # Separar miles con delimitador
        parts = formatted.split('.')
        parts[0] = parts[0].reverse.gsub(/(\d{3})(?=\d)/, "\\1#{delimiter}").reverse
        
        # Unir con el separador decimal
        parts.join(separator)
      end
    end
  end
end

# Simular AppConfig
class AppConfig
  @@prices = {}
  
  def self.set_innertube_price(size, price)
    @@prices[size] = price
  end
  
  def self.get_innertube_price(size)
    @@prices[size] || 0.0
  end
  
  def self.get_all_innertube_prices
    # Retornar un hash con todos los tamaños posibles
    {6 => @@prices[6] || 0.0, 9 => @@prices[9] || 0.0, 12 => @@prices[12] || 0.0, 20 => @@prices[20] || 0.0}
  end
  
  def self.delete_all
    @@prices = {}
  end
end

# Incluir el helper en el test
class SimpleGlassPricesHelperTest < Minitest::Test
  include ActionView::Helpers::NumberHelper
  
  # Copiar el código del helper aquí para testing
  def format_glass_price(price)
    return "No establecido" if price.nil? || price == 0
    amount = price.to_f.round(2)
    formatted = number_with_precision(amount, precision: 2, separator: '.', delimiter: ',')
    "$#{formatted}"
  end

  def calculate_selling_price(buying_price, margin_percentage)
    return 0 if buying_price.nil? || margin_percentage.nil?
    buying_price * (1 + margin_percentage / 100.0)
  end

  def format_innertube_price(size)
    price = AppConfig.get_innertube_price(size)
    return "No establecido" if price.nil? || price == 0
    amount = price.to_f.round(2)
    formatted = number_with_precision(amount, precision: 2, separator: '.', delimiter: ',')
    "$#{formatted}"
  end

  def formatted_innertube_prices
    AppConfig.get_all_innertube_prices.transform_values do |price|
      if price > 0
        amount = price.to_f.round(2)
        formatted = number_with_precision(amount, precision: 2, separator: '.', delimiter: ',')
        "$#{formatted}"
      else
        "No establecido"
      end
    end
  end

  def setup
    AppConfig.delete_all
  end

  def test_format_innertube_price_returns_correct_format_for_valid_price
    AppConfig.set_innertube_price(6, 14400.0)
    result = format_innertube_price(6)
    assert_equal "$14,400.00", result
  end

  def test_format_innertube_price_returns_no_establecido_for_zero_price
    result = format_innertube_price(9) # No price set, returns 0.0
    assert_equal "No establecido", result
  end

  def test_formatted_innertube_prices_returns_hash_with_formatted_prices
    AppConfig.set_innertube_price(6, 12000.0)
    AppConfig.set_innertube_price(12, 18000.0)

    result = formatted_innertube_prices

    assert_equal "$12,000.00", result[6]
    assert_equal "No establecido", result[9]
    assert_equal "$18,000.00", result[12]
    assert_equal "No establecido", result[20]
  end

  def test_format_glass_price_returns_correct_format
    result = format_glass_price(125.50)
    assert_equal "$125.50", result
  end

  def test_format_glass_price_returns_no_establecido_for_nil_or_zero
    assert_equal "No establecido", format_glass_price(nil)
    assert_equal "No establecido", format_glass_price(0)
  end

  def test_calculate_selling_price_calculates_correctly
    result = calculate_selling_price(100.0, 25.0)
    assert_equal 125.0, result
  end

  def test_calculate_selling_price_returns_0_for_blank_values
    assert_equal 0, calculate_selling_price(nil, 25.0)
    assert_equal 0, calculate_selling_price(100.0, nil)
  end
end
