class CreateDvhs < ActiveRecord::Migration[8.0]
  def change
    create_table :dvhs do |t|
      t.references :project, null: false, foreign_key: true
      t.integer :innertube
      t.float :height
      t.float :width
      t.string :location
      t.decimal :price
      t.string :glasscutting1_type
      t.string :glasscutting1_thickness
      t.string :glasscutting1_color
      t.string :glasscutting2_type
      t.string :glasscutting2_thickness
      t.string :glasscutting2_color

      t.timestamps
    end
  end
end
