require "test_helper"

class GlassplateTest < ActiveSupport::TestCase
  def setup
    @glassplate = Glassplate.new(
      width: 600,
      height: 400,
      color: "INC",
      glass_type: "LAM",
      thickness: "4+4",
      quantity: 1
    )
  end

  test "should be valid with valid attributes" do
    assert @glassplate.valid?
  end

  test "should require width" do
    @glassplate.width = nil
    assert_not @glassplate.valid?
    assert_includes @glassplate.errors[:width], "no puede estar en blanco"
  end

  test "should require height" do
    @glassplate.height = nil
    assert_not @glassplate.valid?
    assert_includes @glassplate.errors[:height], "no puede estar en blanco"
  end

  test "should require color" do
    @glassplate.color = nil
    assert_not @glassplate.valid?
    assert_includes @glassplate.errors[:color], "no puede estar en blanco"
  end

  test "should require glass_type" do
    @glassplate.glass_type = nil
    assert_not @glassplate.valid?
    assert_includes @glassplate.errors[:glass_type], "no puede estar en blanco"
  end

  test "should require thickness" do
    @glassplate.thickness = nil
    assert_not @glassplate.valid?
    assert_includes @glassplate.errors[:thickness], "no puede estar en blanco"
  end

  test "should validate width is greater than 0" do
    @glassplate.width = 0
    assert_not @glassplate.valid?
    assert_includes @glassplate.errors[:width], "debe ser mayor que 0"
  end

  test "should validate height is greater than 0" do
    @glassplate.height = -1
    assert_not @glassplate.valid?
    assert_includes @glassplate.errors[:height], "debe ser mayor que 0"
  end

  test "should validate color inclusion" do
    @glassplate.color = "invalid_color"
    assert_not @glassplate.valid?
    assert_includes @glassplate.errors[:color], "debe ser uno de: INC, STB, GRS, BRC, BLS, STG, NTR"
  end

  test "should validate glass_type inclusion" do
    @glassplate.glass_type = "Invalid Type"
    assert_not @glassplate.valid?
    assert_includes @glassplate.errors[:glass_type], "debe ser uno de: LAM, FLO, COL"
  end

  test "full_description should return type thickness and color" do
    assert_equal "LAM 4+4 - INC", @glassplate.full_description
  end

end
