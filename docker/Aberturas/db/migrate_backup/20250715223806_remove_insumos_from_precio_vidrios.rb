class RemoveInsumosFromPrecioVidrios < ActiveRecord::Migration[8.0]
  def change
    remove_column :precio_vidrios, :tamiz, :boolean
    remove_column :precio_vidrios, :hotmelt, :boolean
    remove_column :precio_vidrios, :cinta, :boolean
  end
end
