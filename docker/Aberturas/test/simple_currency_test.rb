#!/usr/bin/env ruby

# Test simple para CurrencyHelper sin dependencias de Rails
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

# Incluir el helper en el test
class SimpleCurrencyHelperTest < Minitest::Test
  include ActionView::Helpers::NumberHelper
  
  # Copiar el código del helper aquí para testing
  def format_argentine_currency(amount, unit: "$", precision: 2)
    return "$0,00" if amount.nil? || amount == "" || amount.to_f == 0.0
    
    # Convertir a float y redondear
    amount = amount.to_f.round(precision)
    
    # Formatear con separadores argentinos
    formatted = number_with_precision(amount, precision: precision, separator: ',', delimiter: '.')
    
    # Agregar el símbolo de moneda
    "#{unit}#{formatted}"
  end
  
  def format_price(amount, unit: "$", precision: 2)
    format_argentine_currency(amount, unit: unit, precision: precision)
  end
  
  def format_number_argentine(number, precision: 2)
    return "N/A" if number.nil? || number == ""
    
    number = number.to_f.round(precision)
    number_with_precision(number, precision: precision, separator: ',', delimiter: '.')
  end

  def test_should_format_argentine_currency_correctly
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

  def test_should_handle_edge_cases
    # Valores nil o vacíos
    assert_equal "$0,00", format_argentine_currency(nil, unit: "$", precision: 2)
    assert_equal "$0,00", format_argentine_currency("", unit: "$", precision: 2)
    assert_equal "$0,00", format_argentine_currency(0, unit: "$", precision: 2)

    # Valores negativos
    assert_equal "$-150,00", format_argentine_currency(-150.00, unit: "$", precision: 2)
    assert_equal "$-1.250,50", format_argentine_currency(-1250.50, unit: "$", precision: 2)
  end

  def test_should_format_numbers_without_currency_symbol
    assert_equal "150,00", format_number_argentine(150.00, precision: 2)
    assert_equal "1.250,50", format_number_argentine(1250.50, precision: 2)
    assert_equal "1.234.567,89", format_number_argentine(1234567.89, precision: 2)
    assert_equal "0,00", format_number_argentine(0, precision: 2)
    assert_equal "N/A", format_number_argentine(nil, precision: 2)
  end

  def test_should_use_format_price_alias
    assert_equal "$150,00", format_price(150.00, unit: "$", precision: 2)
    assert_equal "$1.250,50", format_price(1250.50, unit: "$", precision: 2)
  end
end
