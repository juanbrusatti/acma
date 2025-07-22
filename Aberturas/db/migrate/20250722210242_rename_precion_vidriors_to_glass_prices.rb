class RenamePrecionVidriorsToGlassPrices < ActiveRecord::Migration[8.0]
  def change
    rename_table :precio_vidrios, :glass_prices

    rename_column :glass_prices, :tipo, :type
    rename_column :glass_prices, :grosor, :thickness
    rename_column :glass_prices, :precio, :price
    rename_column :glass_prices, :precio_m2, :price_m2
  end
end
