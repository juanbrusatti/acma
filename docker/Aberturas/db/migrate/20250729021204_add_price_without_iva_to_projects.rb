class AddPriceWithoutIvaToProjects < ActiveRecord::Migration[8.0]
  def change
    add_column :projects, :price_without_iva, :decimal
  end
end
