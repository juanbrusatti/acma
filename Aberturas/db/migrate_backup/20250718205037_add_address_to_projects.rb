class AddAddressToProjects < ActiveRecord::Migration[8.0]
  def change
    add_column :projects, :address, :string
  end
end
