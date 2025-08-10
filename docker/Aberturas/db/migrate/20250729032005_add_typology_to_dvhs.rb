class AddTypologyToDvhs < ActiveRecord::Migration[8.0]
  def change
    add_column :dvhs, :typology, :string
  end
end
