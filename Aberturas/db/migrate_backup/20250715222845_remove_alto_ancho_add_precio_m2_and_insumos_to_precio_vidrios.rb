class RemoveAltoAnchoAddPrecioM2AndInsumosToPrecioVidrios < ActiveRecord::Migration[8.0]
  def change
    remove_column :precio_vidrios, :alto, :decimal
    remove_column :precio_vidrios, :ancho, :decimal
    add_column :precio_vidrios, :precio_m2, :decimal
    add_column :precio_vidrios, :tamiz, :boolean, default: false
    add_column :precio_vidrios, :hotmelt, :boolean, default: false
    add_column :precio_vidrios, :cinta, :boolean, default: false
  end
end
