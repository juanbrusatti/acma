class CreateOfficialRateHistories < ActiveRecord::Migration[8.0]
  def change
    create_table :official_rate_histories do |t|
      t.decimal :rate, precision: 10, scale: 2, null: false
      t.string :source, null: false
      t.datetime :rate_date, null: false
      t.boolean :manual_update, default: false
      t.text :notes
      t.decimal :previous_rate, precision: 10, scale: 2
      t.decimal :change_percentage, precision: 5, scale: 2

      t.timestamps
    end

    add_index :official_rate_histories, :rate_date
    add_index :official_rate_histories, :source
    add_index :official_rate_histories, [:rate_date, :source], unique: true
  end
end
