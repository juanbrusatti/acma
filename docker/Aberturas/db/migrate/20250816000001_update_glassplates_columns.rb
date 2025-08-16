class UpdateGlassplatesColumns < ActiveRecord::Migration[8.0]
  def change
    remove_column :glassplates, :standard_measures, :string
    remove_column :glassplates, :location, :string
    remove_column :glassplates, :work, :string
    remove_column :glassplates, :is_scrap, :boolean
    remove_column :glassplates, :status, :string
    remove_column :glassplates, :origin, :string
    add_column :glassplates, :quantity, :float
  end
end
