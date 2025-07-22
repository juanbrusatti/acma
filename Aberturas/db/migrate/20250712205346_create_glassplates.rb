class CreateGlassplates < ActiveRecord::Migration[8.0]
  def change
    create_table :glassplates do |t|
      t.float :width
      t.float :height
      t.string :color
      t.string :type
      t.boolean :deleted, default: false
      t.timestamps
    end
  end
end
