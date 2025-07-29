class AddPriceToProjects < ActiveRecord::Migration[8.0]
  def change
    add_column :projects, :price, :decimal
  end
end
