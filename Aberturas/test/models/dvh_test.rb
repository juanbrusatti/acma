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
    assert_includes @dvh.errors[:innertube], "La camara del vidrio no es valida"
  end

  test "should require location" do
    @dvh.location = nil
    assert_not @dvh.valid?
    assert_includes @dvh.errors[:location], "La ubicación del vidrio no es valida"
  end

  test "should require height and width" do
    @dvh.height = nil
    @dvh.width = nil
    assert_not @dvh.valid?
    assert_includes @dvh.errors[:height], "El alto del vidrio no puede estar en blanco"
    assert_includes @dvh.errors[:width], "El ancho del vidrio no puede estar en blanco"
  end

  test "should validate location inclusion" do
    @dvh.location = "INVALID_LOCATION"
    assert_not @dvh.valid?
    assert_includes @dvh.errors[:location], "La ubicación del vidrio no es valida"
  end

  test "should validate innertube inclusion" do
    @dvh.innertube = 99
    assert_not @dvh.valid?
    assert_includes @dvh.errors[:innertube], "La camara del vidrio no es valida"
  end

  test "should require glasscutting1 and glasscutting2 fields" do
    @dvh.glasscutting1_type = nil
    assert_not @dvh.valid?
    assert_includes @dvh.errors[:glasscutting1_type], "El tipo de vidrio 1 no puede estar en blanco"
  end

  test "should validate glasscutting1_type inclusion" do
    @dvh.glasscutting1_type = "INVALID"
    assert_not @dvh.valid?
    assert_includes @dvh.errors[:glasscutting1_type], "El tipo de vidrio 1 no es valido"
  end

  test "should validate glasscutting1_thickness inclusion" do
    @dvh.glasscutting1_thickness = "INVALID"
    assert_not @dvh.valid?
    assert_includes @dvh.errors[:glasscutting1_thickness], "El grosor del vidrio 1 no es valido"
  end

  test "should validate glasscutting1_color inclusion" do
    @dvh.glasscutting1_color = "INVALID"
    assert_not @dvh.valid?
    assert_includes @dvh.errors[:glasscutting1_color], "El color del vidrio 1 no es valido"
  end

  test "should trigger typology update on create" do
    project = Project.create!(
      name: "Test Project",
      phone: "123456789",
      description: "Test description"
    )

    # Create a glasscutting first
    glasscutting = project.glasscuttings.create!(
      glass_type: "LAM", thickness: "4+4", color: "INC", location: "DINTEL",
      height: 100, width: 50, price: 100.0
    )

    # Create DVH
    dvh = project.dvhs.create!(
      innertube: 9,
      location: "DINTEL",
      height: 150,
      width: 100,
      glasscutting1_type: "LAM",
      glasscutting1_thickness: "4+4",
      glasscutting1_color: "INC",
      glasscutting2_type: "FLO",
      glasscutting2_thickness: "3+3",
      glasscutting2_color: "GRS",
      price: 300.0
    )

    project.save!

    # DVH should get V2 (after glasscutting V1)
    glasscutting.reload
    dvh.reload
    assert_equal "V1", glasscutting.typology
    assert_equal "V2", dvh.typology
  end

  test "should trigger typology update on destroy" do
    project = Project.create!(
      name: "Test Project",
      phone: "123456789",
      description: "Test description"
    )

    # Create glasscutting and two DVHs
    glasscutting = project.glasscuttings.create!(
      glass_type: "LAM", thickness: "4+4", color: "INC", location: "DINTEL",
      height: 100, width: 50, price: 100.0
    )

    dvh1 = project.dvhs.create!(
      innertube: 9, location: "DINTEL", height: 150, width: 100,
      glasscutting1_type: "LAM", glasscutting1_thickness: "4+4", glasscutting1_color: "INC",
      glasscutting2_type: "FLO", glasscutting2_thickness: "3+3", glasscutting2_color: "GRS",
      price: 300.0
    )

    dvh2 = project.dvhs.create!(
      innertube: 12, location: "JAMBA_I", height: 200, width: 150,
      glasscutting1_type: "COL", glasscutting1_thickness: "5+5", glasscutting1_color: "BRC",
      glasscutting2_type: "LAM", glasscutting2_thickness: "4+4", glasscutting2_color: "STB",
      price: 400.0
    )

    project.save!

    # Verify initial typologies
    glasscutting.reload
    dvh1.reload
    dvh2.reload
    assert_equal "V1", glasscutting.typology
    assert_equal "V2", dvh1.typology
    assert_equal "V3", dvh2.typology

    # Destroy first DVH
    dvh1.destroy!

    # Second DVH should become V2
    glasscutting.reload
    dvh2.reload
    assert_equal "V1", glasscutting.typology
    assert_equal "V2", dvh2.typology
  end
end
