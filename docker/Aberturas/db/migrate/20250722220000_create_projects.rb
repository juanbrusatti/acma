class CreateProjects < ActiveRecord::Migration[8.0]
  def change
    create_table :projects do |t|
      t.string :name
      t.text :description
      t.string :status
      t.date :delivery_date
      t.string :phone
      t.string :address

      t.timestamps precision: nil
    end
  end
end
