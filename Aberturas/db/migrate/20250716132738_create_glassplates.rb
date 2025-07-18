class CreateGlassplates < ActiveRecord::Migration[8.0]
  def change
    create_table :glassplates do |t|
      t.string :name
      t.float :thickness
      t.string :color
      t.timestamps
    end
  end
end
