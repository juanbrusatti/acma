class AddDetailsToDvhs < ActiveRecord::Migration[8.0]
  def change
    add_column :dvhs, :height, :float
    add_column :dvhs, :width, :float
    add_column :dvhs, :location, :string
    add_column :dvhs, :price, :decimal
  end
end
