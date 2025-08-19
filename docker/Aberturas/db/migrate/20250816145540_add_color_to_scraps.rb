class AddColorToScraps < ActiveRecord::Migration[8.0]
  def change
    add_column :scraps, :color, :string
  end
end
