class CreateSupplies < ActiveRecord::Migration[8.0]
  def change
    create_table :supplies do |t|
      t.string :name
      t.decimal :price

      t.timestamps
    end
  end
end
