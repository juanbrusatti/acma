class ChangeDefaultStatusInProjects < ActiveRecord::Migration[7.0]
  def change
    change_column_default :projects, :status, "Pendiente"
  end
end