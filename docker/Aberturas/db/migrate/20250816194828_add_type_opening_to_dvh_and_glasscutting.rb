class AddTypeOpeningToDvhAndGlasscutting < ActiveRecord::Migration[8.0]
  def change
    add_column :dvhs, :type_opening, :string
    add_column :glasscuttings, :type_opening, :string
  end
end
