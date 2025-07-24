class CreateInsumos < ActiveRecord::Migration[8.0]
  def change
    create_table :insumos do |t|
      t.string :nombre
      t.decimal :precio

      t.timestamps
    end
  end
end
