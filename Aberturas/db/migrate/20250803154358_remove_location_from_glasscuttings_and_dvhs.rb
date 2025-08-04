class RemoveLocationFromGlasscuttingsAndDvhs < ActiveRecord::Migration[8.0]
  def change
    remove_column :glasscuttings, :location, :string
    remove_column :dvhs, :location, :string
  end
end
