class AddPhoneToProjects < ActiveRecord::Migration[8.0]
  def change
    add_column :projects, :phone, :string
  end
end
