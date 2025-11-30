class RemovePriceWithoutIvaFromProjects < ActiveRecord::Migration[8.0]
  def change
    remove_column :projects, :price_without_iva, :decimal
  end
end
