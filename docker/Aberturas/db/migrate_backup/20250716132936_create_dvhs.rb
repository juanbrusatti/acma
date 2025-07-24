class CreateDvhs < ActiveRecord::Migration[8.0]
  def change
    create_table :dvhs do |t|
      t.references :project, null: false, foreign_key: true
      t.integer :innertube

      t.timestamps
    end
  end
end
