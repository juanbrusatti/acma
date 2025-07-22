class AddFieldsToGlassplates < ActiveRecord::Migration[8.0]
  def change
    add_column :glassplates, :thickness, :string
    add_column :glassplates, :standard_measures, :string
    add_column :glassplates, :location, :string
    add_column :glassplates, :is_scrap, :boolean
  end
end
