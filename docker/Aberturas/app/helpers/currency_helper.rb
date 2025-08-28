module CurrencyHelper
  # Formatea un precio usando el formato argentino: punto para miles, coma para decimales
  # Ejemplo: 1234567.89 -> $1.234.567,89
  def format_argentine_currency(amount, unit: "$", precision: 2)
    return "$0,00" if amount.nil? || amount == "" || amount.to_f == 0.0
    
    # Convertir a float y redondear
    amount = amount.to_f.round(precision)
    
    # Formatear con separadores argentinos
    formatted = number_with_precision(amount, precision: precision, separator: ',', delimiter: '.')
    
    # Agregar el símbolo de moneda
    "#{unit}#{formatted}"
  end
  
  # Alias para compatibilidad
  def format_price(amount, unit: "$", precision: 2)
    format_argentine_currency(amount, unit: unit, precision: precision)
  end
  
  # Formatea un precio sin símbolo de moneda
  def format_number_argentine(number, precision: 2)
    return "N/A" if number.blank?
    
    number = number.to_f.round(precision)
    number_with_precision(number, precision: precision, separator: ',', delimiter: '.')
  end
end
