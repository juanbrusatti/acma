class AddDateOfOptimizationToProject < ActiveRecord::Migration[8.0]
  def change
    add_column :projects, :date_of_optimization, :date
  end
end
