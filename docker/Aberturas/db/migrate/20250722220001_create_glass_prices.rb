class CreateGlassPrices < ActiveRecord::Migration[8.0]
  def change
    create_table :glass_prices do |t|
      t.string :color
      t.string :glass_type
      t.decimal :thickness
      t.decimal :price
      t.decimal :price_m2

      t.timestamps
    end
  end
end
