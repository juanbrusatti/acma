class RenameTypeToGlassTypeInGlassplates < ActiveRecord::Migration[8.0]
  def change
    rename_column :glassplates, :type, :glass_type
  end
end
