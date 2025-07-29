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
      location: "DINTEL",
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
    assert_includes @glasscutting.errors[:location], "debe ser uno de: DINTEL, JAMBA_I, JAMBA_D, UMBRAL"
  end

  test "should trigger typology update on create" do
    project = Project.create!(
      name: "Test Project",
      phone: "123456789",
      description: "Test description"
    )

    # Create first glasscutting
    glasscutting1 = project.glasscuttings.create!(
      glass_type: "LAM",
      thickness: "4+4",
      color: "INC",
      location: "DINTEL",
      height: 100,
      width: 50,
      price: 100.0
    )

    project.save!
    glasscutting1.reload
    assert_equal "V1", glasscutting1.typology

    # Create second glasscutting
    glasscutting2 = project.glasscuttings.create!(
      glass_type: "FLO",
      thickness: "3+3",
      color: "GRS",
      location: "JAMBA_I",
      height: 200,
      width: 75,
      price: 200.0
    )

    # Both glasscuttings should have correct typologies
    glasscutting1.reload
    glasscutting2.reload
    assert_equal "V1", glasscutting1.typology
    assert_equal "V2", glasscutting2.typology
  end

  test "should trigger typology update on destroy" do
    project = Project.create!(
      name: "Test Project",
      phone: "123456789",
      description: "Test description"
    )

    # Create two glasscuttings
    glasscutting1 = project.glasscuttings.create!(
      glass_type: "LAM", thickness: "4+4", color: "INC", location: "DINTEL",
      height: 100, width: 50, price: 100.0
    )
    
    glasscutting2 = project.glasscuttings.create!(
      glass_type: "FLO", thickness: "3+3", color: "GRS", location: "JAMBA_I",
      height: 200, width: 75, price: 200.0
    )

    project.save!

    # Verify initial typologies
    glasscutting1.reload
    glasscutting2.reload
    assert_equal "V1", glasscutting1.typology
    assert_equal "V2", glasscutting2.typology

    # Destroy first glasscutting
    glasscutting1.destroy!

    # Second glasscutting should become V1
    glasscutting2.reload
    assert_equal "V1", glasscutting2.typology
  end
end
