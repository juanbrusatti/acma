class ChangeBigintToIntegerForForeignKeys < ActiveRecord::Migration[8.0]
  def change
    # Cambiar columnas en la tabla dvhs
    change_column :dvhs, :scrap1_id, :integer
    change_column :dvhs, :scrap2_id, :integer
    
    # Cambiar columnas en la tabla glasscuttings
    change_column :glasscuttings, :scrap_id, :integer
    change_column :glasscuttings, :project_id, :integer, null: false
  end
end
