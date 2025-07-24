class CreateGlasscuttings < ActiveRecord::Migration[8.0]
  def change
    create_table :glasscuttings do |t|
      t.float :height
      t.float :width
      t.string :color
      t.string :glass_type
      t.string :location
      t.decimal :price
      t.references :project, null: false, foreign_key: true
      t.references :glassplate, null: false, foreign_key: true

      t.timestamps
    end
  end
end
