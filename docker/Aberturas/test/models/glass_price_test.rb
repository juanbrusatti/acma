require "test_helper"

class GlassPriceTest < ActiveSupport::TestCase
  def setup
    @glass_price = GlassPrice.new(
      glass_type: "LAM",
      thickness: "3+3",
      color: "INC",
      buying_price: 100.0,
      percentage: 25.0
    )
  end

  test "should be valid with valid attributes" do
    assert @glass_price.valid?
  end

  test "should calculate selling price automatically before save" do
    @glass_price.save
    expected_selling_price = 100.0 * (1 + 25.0 / 100.0)
    assert_equal expected_selling_price, @glass_price.selling_price
  end

  test "should update selling price when buying price changes" do
    @glass_price.save
    @glass_price.update(buying_price: 200.0)
    expected_selling_price = 200.0 * (1 + 25.0 / 100.0)
    assert_equal expected_selling_price, @glass_price.selling_price
  end

  test "should update selling price when percentage changes" do
    @glass_price.save
    @glass_price.update(percentage: 50.0)
    expected_selling_price = 100.0 * (1 + 50.0 / 100.0)
    assert_equal expected_selling_price, @glass_price.selling_price
  end

  test "should not calculate selling price if buying price is blank" do
    @glass_price.buying_price = nil
    @glass_price.save
    assert_nil @glass_price.selling_price
  end

  test "should not calculate selling price if percentage is blank" do
    @glass_price.percentage = nil
    @glass_price.save
    assert_nil @glass_price.selling_price
  end

  test "combinations_possible should return all valid combinations" do
    combinations = GlassPrice.combinations_possible
    
    # Should include LAM combinations
    assert_includes combinations, { glass_type: "LAM", thickness: "3+3", color: "INC" }
    assert_includes combinations, { glass_type: "LAM", thickness: "3+3", color: "BLS" }
    assert_includes combinations, { glass_type: "LAM", thickness: "4+4", color: "INC" }
    assert_includes combinations, { glass_type: "LAM", thickness: "5+5", color: "INC" }
    
    # Should include FLO combinations
    assert_includes combinations, { glass_type: "FLO", thickness: "5mm", color: "GRS" }
    assert_includes combinations, { glass_type: "FLO", thickness: "5mm", color: "BRC" }
    assert_includes combinations, { glass_type: "FLO", thickness: "5mm", color: "INC" }
    
    # Should include COL combinations
    assert_includes combinations, { glass_type: "COL", thickness: "4+4", color: "STB" }
    assert_includes combinations, { glass_type: "COL", thickness: "4+4", color: "STG" }
    assert_includes combinations, { glass_type: "COL", thickness: "4+4", color: "NTR" }
  end

  test "find_or_build_by_comb should find existing record" do
    existing_price = GlassPrice.create!(
      glass_type: "LAM",
      thickness: "3+3", 
      color: "INC",
      buying_price: 50.0,
      percentage: 20.0
    )

    found_price = GlassPrice.find_or_build_by_comb(
      glass_type: "LAM",
      thickness: "3+3",
      color: "INC"
    )

    assert_equal existing_price.id, found_price.id
    assert found_price.persisted?
  end

  test "find_or_build_by_comb should build new record if not found" do
    new_price = GlassPrice.find_or_build_by_comb(
      glass_type: "FLO",
      thickness: "5mm",
      color: "GRS"
    )

    assert new_price.new_record?
    assert_equal "FLO", new_price.glass_type
    assert_equal "5mm", new_price.thickness
    assert_equal "GRS", new_price.color
  end

  test "should handle zero percentage correctly" do
    @glass_price.percentage = 0.0
    @glass_price.save
    assert_equal @glass_price.buying_price, @glass_price.selling_price
  end

  test "should handle negative percentage correctly" do
    @glass_price.percentage = -10.0
    @glass_price.save
    expected_selling_price = 100.0 * (1 + (-10.0) / 100.0)
    assert_equal expected_selling_price, @glass_price.selling_price
  end

  test "should preserve existing selling price if buying price and percentage are blank" do
    @glass_price.selling_price = 150.0
    @glass_price.buying_price = nil
    @glass_price.percentage = nil
    @glass_price.save
    assert_equal 150.0, @glass_price.selling_price
  end
end
