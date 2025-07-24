class CreatePrecioVidrios < ActiveRecord::Migration[8.0]
  def change
    create_table :precio_vidrios do |t|
      t.decimal :alto
      t.decimal :ancho
      t.string :color
      t.string :tipo
      t.decimal :grosor
      t.decimal :precio

      t.timestamps
    end
  end
end
