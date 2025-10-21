class DeleteStatusAndOutputWorkFromScrap < ActiveRecord::Migration[8.0]
  def change
    remove_column :scraps, :status, :string
    remove_column :scraps, :output_work, :string
    add_column :scraps, :input_work, :string
  end
end
