class AddStatusAndDeliveryDateToProjects < ActiveRecord::Migration[8.0]
  def change
    add_column :projects, :status, :string
    add_column :projects, :delivery_date, :date
  end
end
