class AddAtributesToGlassplates < ActiveRecord::Migration[8.0]
  def change
    add_column :glassplates, :work, :string
    add_column :glassplates, :origin, :string
    remove_column :glassplates, :quantity, :integer
  end
end
