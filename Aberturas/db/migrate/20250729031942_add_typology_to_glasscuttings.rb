class AddTypologyToGlasscuttings < ActiveRecord::Migration[8.0]
  def change
    add_column :glasscuttings, :typology, :string
  end
end
