class RenameInsumosToSupplies < ActiveRecord::Migration[8.0]
  def change
    # Renombrar tabla de insumos a supplies
    rename_table :insumos, :supplies

    # Renombrar columnas de español a inglés
    rename_column :supplies, :nombre, :name
    rename_column :supplies, :precio, :price
  end
end
