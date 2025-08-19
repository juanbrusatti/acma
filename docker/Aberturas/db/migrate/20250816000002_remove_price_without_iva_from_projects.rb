class RemovePriceWithoutIvaFromProjects < ActiveRecord::Migration[8.0]
  def change
    remove_column :projects, :priceWithoutIva, :decimal
  end
end
