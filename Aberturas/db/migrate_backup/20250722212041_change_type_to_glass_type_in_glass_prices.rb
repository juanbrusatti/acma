class ChangeTypeToGlassTypeInGlassPrices < ActiveRecord::Migration[8.0]
  def change
    rename_column :glass_prices, :type, :glass_type
  end
end
