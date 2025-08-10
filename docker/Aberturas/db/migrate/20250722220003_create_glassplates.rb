class CreateGlassplates < ActiveRecord::Migration[8.0]
  def change
    create_table :glassplates do |t|
      t.float :width
      t.float :height
      t.string :color
      t.string :glass_type
      t.string :thickness
      t.string :standard_measures
      t.string :location
      t.string :work
      t.string :origin
      t.string :status
      t.boolean :deleted, default: false
      t.boolean :is_scrap

      t.timestamps
    end
  end
end
