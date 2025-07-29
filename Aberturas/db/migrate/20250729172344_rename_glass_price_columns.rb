class RenameGlassPriceColumns < ActiveRecord::Migration[8.0]
  def change
    # Renombrar price a buying_price
    rename_column :glass_prices, :price, :buying_price
    
    # Renombrar price_m2 a selling_price (que será el precio de venta por m²)
    rename_column :glass_prices, :price_m2, :selling_price
    
    # Agregar columna percentage para manejar el porcentaje de ganancia
    add_column :glass_prices, :percentage, :decimal, precision: 5, scale: 2
  end
end
