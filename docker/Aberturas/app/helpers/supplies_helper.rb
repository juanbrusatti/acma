module SuppliesHelper
  # Format supply USD price for display
  def format_supply_usd_price(supply)
    if supply.price_usd.present? && supply.price_usd > 0
      # Formatear con punto como separador decimal para USD
      amount = supply.price_usd.to_f.round(2)
      formatted = number_with_precision(amount, precision: 2, separator: '.', delimiter: ',')
      "US$#{formatted}"
    else
      "N/A"
    end
  end

  # Format supply peso price for display
  def format_supply_peso_price(supply)
    if supply.price_peso.present? && supply.price_peso > 0
      format_argentine_currency(supply.price_peso, unit: "$", precision: 2)
    else
      "N/A"
    end
  end

  # Legacy method for backwards compatibility - now uses USD price
  def format_supply_price(supply)
    format_supply_usd_price(supply)
  end

  # Generate CSS classes for supply price display (based on USD price)
  def supply_price_class(supply)
    if supply.price_usd.present? && supply.price_usd > 0
      "font-semibold text-green-700"
    else
      "font-semibold text-gray-500"
    end
  end

  # Check if supply has valid USD price
  def supply_has_price?(supply)
    supply.price_usd.present? && supply.price_usd > 0
  end
end
