class RenameGlassPriceColumns < ActiveRecord::Migration[8.0]
  def change
    rename_column :glass_prices, :price, :buying_price
    rename_column :glass_prices, :price_m2, :selling_price
    add_column :glass_prices, :percentage, :decimal, precision: 5, scale: 2
  end
end
