class CreateScraps < ActiveRecord::Migration[8.0]
  def change
    create_table :scraps do |t|
      t.string :ref_number
      t.string :scrap_type
      t.string :thickness
      t.float :width
      t.float :height
      t.string :output_work
      t.string :status

      t.timestamps
    end
  end
end
