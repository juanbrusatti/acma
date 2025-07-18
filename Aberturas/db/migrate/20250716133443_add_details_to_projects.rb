class AddDetailsToProjects < ActiveRecord::Migration[8.0]
  def change
    add_column :projects, :phone, :string
    add_column :projects, :address, :string
  end
end
