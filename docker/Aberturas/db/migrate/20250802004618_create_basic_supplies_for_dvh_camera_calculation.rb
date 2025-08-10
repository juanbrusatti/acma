class CreateBasicSuppliesForDvhCameraCalculation < ActiveRecord::Migration[8.0]
  def change
    # Ensure we have all basic supplies needed for DVH camera calculations
    # Prices will be set from the glass_prices interface
    basic_supplies = [
      { name: 'Perfil separador' },  # Per linear meter
      { name: 'Angulos' },           # Per unit
      { name: 'Tamiz' },             # Per kilogram
      { name: 'Cinta' },             # Per linear meter 
      { name: 'Hotmelt' }            # Per kilogram
    ]

    basic_supplies.each do |supply_data|
      # Only create if it doesn't exist
      supply = Supply.find_or_initialize_by(name: supply_data[:name])
      if supply.new_record?
        supply.price_usd = 0.0  # Will be set from glass_prices interface
        supply.price_peso = 0.0
        supply.save!
        puts "Created supply: #{supply_data[:name]} - set price from glass_prices interface"
      else
        puts "Supply already exists: #{supply_data[:name]}"
      end
    end
    
    puts "Basic supplies created. Configure prices from the glass_prices interface."
  end
end
