class MakeDvhAndGlassplateNullableInGlasscuttings < ActiveRecord::Migration[8.0]
  def change
    change_column_null :glasscuttings, :dvh_id, true
    change_column_null :glasscuttings, :glassplate_id, true
  end
end
