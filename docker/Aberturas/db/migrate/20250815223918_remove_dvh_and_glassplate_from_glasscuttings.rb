class RemoveDvhAndGlassplateFromGlasscuttings < ActiveRecord::Migration[8.0]
  def change
    remove_reference :glasscuttings, :dvh, null: false, foreign_key: true
    remove_reference :glasscuttings, :glassplate, null: false, foreign_key: true
  end
end
