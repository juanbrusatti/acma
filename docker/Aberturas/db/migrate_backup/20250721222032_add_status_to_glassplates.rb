class AddStatusToGlassplates < ActiveRecord::Migration[8.0]
  def change
    add_column :glassplates, :status, :string
  end
end
