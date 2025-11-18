class ChangeRefNumberToIntegerInScraps < ActiveRecord::Migration[8.0]
  def change
    change_column :scraps, :ref_number, :integer, using: 'ref_number::integer'
  end
end
