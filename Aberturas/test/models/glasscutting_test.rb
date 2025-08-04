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
      typology: "V1"
    )
  end

  test "should be valid with valid attributes" do
    assert @glasscutting.valid?
  end

  test "should require glass_type" do
    @glasscutting.glass_type = nil
    assert_not @glasscutting.valid?
    assert_includes @glasscutting.errors[:glass_type], "El tipo de vidrio no puede estar en blanco"
  end

  test "should require thickness" do
    @glasscutting.thickness = nil
    assert_not @glasscutting.valid?
    assert_includes @glasscutting.errors[:thickness], "El espesor del vidrio no puede estar en blanco"
  end

  test "should require color" do
    @glasscutting.color = nil
    assert_not @glasscutting.valid?
    assert_includes @glasscutting.errors[:color], "El color del vidrio no puede estar en blanco"
  end

  test "should require typology" do
    @glasscutting.typology = nil
    assert_not @glasscutting.valid?
    assert_includes @glasscutting.errors[:typology], "La tipología del vidrio no puede estar en blanco"
  end

  test "should require height and width" do
    @glasscutting.height = nil
    @glasscutting.width = nil
    assert_not @glasscutting.valid?
    assert_includes @glasscutting.errors[:height], "El alto del vidrio no puede estar en blanco"
    assert_includes @glasscutting.errors[:width], "El ancho del vidrio no puede estar en blanco"
  end

  test "should validate glass_type inclusion" do
    @glasscutting.glass_type = "INVALID"
    assert_not @glasscutting.valid?
    assert_includes @glasscutting.errors[:glass_type], "El tipo de vidrio no es valido"
  end

  test "should validate thickness inclusion" do
    @glasscutting.thickness = "INVALID"
    assert_not @glasscutting.valid?
    assert_includes @glasscutting.errors[:thickness], "El grosor del vidrios no es valido"
  end

  test "should validate color inclusion" do
    @glasscutting.color = "INVALID"
    assert_not @glasscutting.valid?
    assert_includes @glasscutting.errors[:color], "Color de vidrio no valido"
  end

  test "should allow any typology format" do
    # Test various typology formats
    valid_typologies = ["V1", "V10", "V123", "V5", "Custom1", "ABC123"]
    
    valid_typologies.each do |typology|
      @glasscutting.typology = typology
      assert @glasscutting.valid?, "Typology '#{typology}' should be valid"
    end
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
      typology: "V1",
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
      typology: "V2",
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

  test "should maintain typology on destroy" do
    project = Project.create!(
      name: "Test Project",
      phone: "123456789",
      description: "Test description"
    )

    # Create two glasscuttings
    glasscutting1 = project.glasscuttings.create!(
      glass_type: "LAM", thickness: "4+4", color: "INC", typology: "V1",
      height: 100, width: 50, price: 100.0
    )
    
    glasscutting2 = project.glasscuttings.create!(
      glass_type: "FLO", thickness: "3+3", color: "GRS", typology: "V2",
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

    # Second glasscutting should keep its typology unchanged
    glasscutting2.reload
    assert_equal "V2", glasscutting2.typology
  end
end
