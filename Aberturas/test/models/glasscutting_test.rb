require "test_helper"

class GlasscuttingTest < ActiveSupport::TestCase
  def setup
    @project = projects(:one)
    @glasscutting = Glasscutting.new(
      project: @project,
      glass_type: "LAM",
      thickness: "3+3",
      height: 1000,
      width: 800,
      color: "INC",
      location: "DINTER"
    )
  end

  test "should be valid with valid attributes" do
    assert @glasscutting.valid?
  end

  test "should require glass_type" do
    @glasscutting.glass_type = nil
    assert_not @glasscutting.valid?
    assert_includes @glasscutting.errors[:glass_type], "can't be blank"
  end

  test "should require thickness" do
    @glasscutting.thickness = nil
    assert_not @glasscutting.valid?
    assert_includes @glasscutting.errors[:thickness], "can't be blank"
  end

  test "should require color" do
    @glasscutting.color = nil
    assert_not @glasscutting.valid?
    assert_includes @glasscutting.errors[:color], "can't be blank"
  end

  test "should require location" do
    @glasscutting.location = nil
    assert_not @glasscutting.valid?
    assert_includes @glasscutting.errors[:location], "can't be blank"
  end

  test "should require height and width" do
    @glasscutting.height = nil
    @glasscutting.width = nil
    assert_not @glasscutting.valid?
    assert_includes @glasscutting.errors[:height], "can't be blank"
    assert_includes @glasscutting.errors[:width], "can't be blank"
  end

  test "should validate glass_type inclusion" do
    @glasscutting.glass_type = "INVALID"
    assert_not @glasscutting.valid?
    assert_includes @glasscutting.errors[:glass_type], "debe ser uno de: LAM, FLO, COL"
  end

  test "should validate thickness inclusion" do
    @glasscutting.thickness = "INVALID"
    assert_not @glasscutting.valid?
    assert_includes @glasscutting.errors[:thickness], "debe ser uno de: 3+3, 4+4, 5+5, 5mm"
  end

  test "should validate color inclusion" do
    @glasscutting.color = "INVALID"
    assert_not @glasscutting.valid?
    assert_includes @glasscutting.errors[:color], "debe ser uno de: INC, STB, GRS, BRC, BLS, STG, NTR"
  end

  test "should validate location inclusion" do
    @glasscutting.location = "INVALID"
    assert_not @glasscutting.valid?
    assert_includes @glasscutting.errors[:location], "debe ser uno de: DINTER, JAMBA_I, JAMBA_D, UMBRAL"
  end
end
