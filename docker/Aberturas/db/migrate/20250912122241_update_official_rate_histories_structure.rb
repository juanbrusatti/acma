class UpdateOfficialRateHistoriesStructure < ActiveRecord::Migration[8.0]
  def change
    # Renombrar columnas existentes
    rename_column :official_rate_histories, :date, :rate_date
    rename_column :official_rate_histories, :is_manual, :manual_update
    
    # Agregar nuevas columnas
    add_column :official_rate_histories, :previous_rate, :decimal, precision: 10, scale: 2
    add_column :official_rate_histories, :change_percentage, :decimal, precision: 5, scale: 2
    
    # Agregar índices solo si no existen
    add_index :official_rate_histories, :rate_date unless index_exists?(:official_rate_histories, :rate_date)
    add_index :official_rate_histories, :source unless index_exists?(:official_rate_histories, :source)
    add_index :official_rate_histories, [:rate_date, :source], unique: true unless index_exists?(:official_rate_histories, [:rate_date, :source])
  end
end
