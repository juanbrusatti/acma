class AddLocationToScraps < ActiveRecord::Migration[8.0]
  def change
    add_column :scraps, :location, :string
  end
end
