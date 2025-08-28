module GlassPricesHelper
  # Build glass price combinations and initialize missing records
  def build_glass_price_combinations
    GlassPrice.combinations_possible.map do |combination|
      record = GlassPrice.find_or_initialize_by(combination)
      if record.new_record?
        record.save(validate: false)
      end
      record
    end
  end

  # Format price for display
  def format_glass_price(price)
    return "No establecido" if price.blank? || price.zero?
    amount = price.to_f.round(2)
    formatted = number_with_precision(amount, precision: 2, separator: '.', delimiter: ',')
    "$#{formatted}"
  end

  # Calculate selling price from buying price and margin
  def calculate_selling_price(buying_price, margin_percentage)
    return 0 if buying_price.blank? || margin_percentage.blank?
    buying_price * (1 + margin_percentage / 100.0)
  end

  # Format innertube price for display
  def format_innertube_price(size)
  price = AppConfig.get_innertube_price(size)
  return "No establecido" if price.blank? || price.zero?
  amount = price.to_f.round(2)
  formatted = number_with_precision(amount, precision: 2, separator: '.', delimiter: ',')
  "$#{formatted}"
  end

  # Get all innertube prices formatted for display
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
end
