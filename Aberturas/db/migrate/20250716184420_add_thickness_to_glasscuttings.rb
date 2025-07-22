class AddThicknessToGlasscuttings < ActiveRecord::Migration[8.0]
  def change
    add_column :glasscuttings, :thickness, :string
  end
end
