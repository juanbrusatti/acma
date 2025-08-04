class CreateAppConfigs < ActiveRecord::Migration[8.0]
  def change
    create_table :app_configs do |t|
      t.string :key
      t.string :value

      t.timestamps
    end
  end
end
