require "test_helper"

class DvhTest < ActiveSupport::TestCase
  def setup
    @project = projects(:one)
    @dvh = Dvh.new(
      project: @project,
      innertube: "6",
      location: "DINTEL",
      height: 1000,
      width: 800,
      glasscutting1_type: "LAM",
      glasscutting1_thickness: "3+3",
      glasscutting1_color: "INC",
      glasscutting2_type: "FLO",
      glasscutting2_thickness: "4+4",
      glasscutting2_color: "GRS"
    )
  end

  test "should be valid with valid attributes" do
    valid = @dvh.valid?
    puts @dvh.errors.full_messages unless valid
    assert valid
  end

  test "should require innertube" do
    @dvh.innertube = nil
    assert_not @dvh.valid?
    assert_includes @dvh.errors[:innertube], "can't be blank"
  end

  test "should require location" do
    @dvh.location = nil
    assert_not @dvh.valid?
    assert_includes @dvh.errors[:location], "can't be blank"
  end

  test "should require height and width" do
    @dvh.height = nil
    @dvh.width = nil
    assert_not @dvh.valid?
    assert_includes @dvh.errors[:height], "can't be blank"
    assert_includes @dvh.errors[:width], "can't be blank"
  end

  test "should validate location inclusion" do
    @dvh.location = "INVALID"
    assert_not @dvh.valid?
    assert_includes @dvh.errors[:location], "debe ser uno de: DINTEL, JAMBA_I, JAMBA_D, UMBRAL"
  end

  test "should validate innertube inclusion" do
    @dvh.innertube = 99
    assert_not @dvh.valid?
    assert_includes @dvh.errors[:innertube], "debe ser uno de: 6, 9, 12, 20"
  end

  test "should require glasscutting1 and glasscutting2 fields" do
    @dvh.glasscutting1_type = nil
    @dvh.glasscutting2_type = nil
    assert_not @dvh.valid?
    assert_includes @dvh.errors[:glasscutting1_type], "can't be blank"
    assert_includes @dvh.errors[:glasscutting2_type], "can't be blank"
  end

  test "should validate glasscutting1_type inclusion" do
    @dvh.glasscutting1_type = "INVALID"
    assert_not @dvh.valid?
    assert_includes @dvh.errors[:glasscutting1_type], "debe ser uno de: LAM, FLO, COL"
  end

  test "should validate glasscutting1_thickness inclusion" do
    @dvh.glasscutting1_thickness = "INVALID"
    assert_not @dvh.valid?
    assert_includes @dvh.errors[:glasscutting1_thickness], "debe ser uno de: 3+3, 4+4, 5+5, 5mm"
  end

  test "should validate glasscutting1_color inclusion" do
    @dvh.glasscutting1_color = "INVALID"
    assert_not @dvh.valid?
    assert_includes @dvh.errors[:glasscutting1_color], "debe ser uno de: INC, STB, GRS, BRC, BLS, STG, NTR"
  end
end
