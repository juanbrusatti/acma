#!/usr/bin/env ruby

# Test simple para SuppliesHelper sin dependencias de Rails
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

# Simular el modelo Supply
class Supply
  attr_accessor :name, :price_usd, :price_peso
  
  def initialize(attributes = {})
    @name = attributes[:name]
    @price_usd = attributes[:price_usd]
    @price_peso = attributes[:price_peso]
  end
  
  def price_usd
    @price_usd
  end
  
  def price_peso
    @price_peso
  end
end

# Incluir el helper en el test
class SimpleSuppliesHelperTest < Minitest::Test
  include ActionView::Helpers::NumberHelper
  
  # Copiar el código del helper aquí para testing
  def format_supply_usd_price(supply)
    if supply.price_usd && supply.price_usd > 0
      # Formatear con punto como separador decimal para USD
      amount = supply.price_usd.to_f.round(2)
      formatted = number_with_precision(amount, precision: 2, separator: '.', delimiter: ',')
      "US$#{formatted}"
    else
      "N/A"
    end
  end

  def format_supply_peso_price(supply)
    if supply.price_peso && supply.price_peso > 0
      format_argentine_currency(supply.price_peso, unit: "$", precision: 2)
    else
      "N/A"
    end
  end

  def format_supply_price(supply)
    format_supply_usd_price(supply)
  end

  def supply_price_class(supply)
    if supply.price_usd && supply.price_usd > 0
      "font-semibold text-green-700"
    else
      "font-semibold text-gray-500"
    end
  end

  def supply_has_price?(supply)
    supply.price_usd && supply.price_usd > 0
  end
  
  # Métodos del CurrencyHelper que necesitamos
  def format_argentine_currency(amount, unit: "$", precision: 2)
    return "$0,00" if amount.nil? || amount == "" || amount.to_f == 0.0
    
    # Convertir a float y redondear
    amount = amount.to_f.round(precision)
    
    # Formatear con separadores argentinos
    formatted = number_with_precision(amount, precision: precision, separator: ',', delimiter: '.')
    
    # Agregar el símbolo de moneda
    "#{unit}#{formatted}"
  end

  def setup
    @supply_with_price = Supply.new(name: "Test Supply", price_usd: 25.50)
    @supply_without_price = Supply.new(name: "Test Supply", price_usd: nil)
    @supply_zero_price = Supply.new(name: "Test Supply", price_usd: 0)
    @supply_with_peso_price = Supply.new(name: "Test Supply", price_peso: 1250.75)
  end

  def test_format_supply_price_should_format_valid_price
    result = format_supply_price(@supply_with_price)
    assert_equal "US$25.50", result
  end

  def test_format_supply_price_should_handle_nil_price
    result = format_supply_price(@supply_without_price)
    assert_equal "N/A", result
  end

  def test_format_supply_price_should_handle_zero_price
    result = format_supply_price(@supply_zero_price)
    assert_equal "N/A", result
  end

  def test_supply_price_class_should_return_green_for_valid_price
    result = supply_price_class(@supply_with_price)
    assert_equal "font-semibold text-green-700", result
  end

  def test_supply_price_class_should_return_gray_for_invalid_price
    result = supply_price_class(@supply_without_price)
    assert_equal "font-semibold text-gray-500", result
  end

  def test_supply_has_price_should_return_true_for_valid_price
    assert supply_has_price?(@supply_with_price)
  end

  def test_supply_has_price_should_return_false_for_invalid_price
    assert !supply_has_price?(@supply_without_price)
    assert !supply_has_price?(@supply_zero_price)
  end
  
  def test_format_supply_peso_price_should_format_valid_price
    result = format_supply_peso_price(@supply_with_peso_price)
    assert_equal "$1.250,75", result
  end
  
  def test_format_supply_usd_price_should_format_valid_price
    result = format_supply_usd_price(@supply_with_price)
    assert_equal "US$25.50", result
  end
end
