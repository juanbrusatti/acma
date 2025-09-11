class CreateMepRateHistories < ActiveRecord::Migration[8.0]
  def change
    create_table :mep_rate_histories do |t|
      t.decimal :rate, precision: 10, scale: 2, null: false
      t.string :source, null: false
      t.date :date, null: false
      t.text :notes
      t.boolean :is_manual, default: false

      t.timestamps
    end
    
    add_index :mep_rate_histories, :date, unique: true
    add_index :mep_rate_histories, :source
  end
end
