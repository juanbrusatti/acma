class AddScrapAssociations < ActiveRecord::Migration[8.0]
  def change
    add_reference :dvhs, :scrap1, foreign_key: { to_table: :scraps }, null: true
    add_reference :dvhs, :scrap2, foreign_key: { to_table: :scraps }, null: true
    add_reference :glasscuttings, :scrap, foreign_key: true, null: true
  end
end
