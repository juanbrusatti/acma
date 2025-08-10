class ModifySuppliesPriceColumns < ActiveRecord::Migration[8.0]
  def change
    # Remove the old price column
    remove_column :supplies, :price, :decimal, precision: 10, scale: 2 if column_exists?(:supplies, :price)
    
    # Add new columns for USD and peso prices
    add_column :supplies, :price_usd, :decimal, precision: 10, scale: 2, default: 0.0, null: false
    add_column :supplies, :price_peso, :decimal, precision: 10, scale: 2, default: 0.0, null: false
    
    # Add index for better performance on price queries
    add_index :supplies, :price_usd
    add_index :supplies, :price_peso
  end
end
