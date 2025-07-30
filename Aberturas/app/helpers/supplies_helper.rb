module SuppliesHelper
  # Format supply price for display
  def format_supply_price(supply)
    if supply.price.present? && supply.price > 0
      number_to_currency(supply.price, unit: "$", precision: 2)
    else
      "N/A"
    end
  end

  # Generate CSS classes for supply price display
  def supply_price_class(supply)
    if supply.price.present? && supply.price > 0
      "font-semibold text-green-700"
    else
      "font-semibold text-gray-500"
    end
  end

  # Check if supply has valid price
  def supply_has_price?(supply)
    supply.price.present? && supply.price > 0
  end
end
