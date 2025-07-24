class ChangeThicknessTypeInGlassPrices < ActiveRecord::Migration[6.0]
  def change
    change_column :glass_prices, :thickness, :string
  end
end