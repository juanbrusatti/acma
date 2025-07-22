class AddMoreDetailsToDvhs < ActiveRecord::Migration[8.0]
  def change
    add_column :dvhs, :glasscutting1_type, :string
    add_column :dvhs, :glasscutting1_thickness, :string
    add_column :dvhs, :glasscutting1_color, :string
    add_column :dvhs, :glasscutting2_type, :string
    add_column :dvhs, :glasscutting2_thickness, :string
    add_column :dvhs, :glasscutting2_color, :string
  end
end
