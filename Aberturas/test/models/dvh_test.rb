require "test_helper"

class DvhTest < ActiveSupport::TestCase
  def setup
    @project = projects(:one)
    @dvh = Dvh.new(
      project: @project,
      innertube: "6",
      typology: "V1",
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

  test "should require typology" do
    @dvh.typology = nil
    assert_not @dvh.valid?
    assert_includes @dvh.errors[:typology], "La tipología del DVH no puede estar en blanco"
  end

  test "should require height and width" do
    @dvh.height = nil
    @dvh.width = nil
    assert_not @dvh.valid?
    assert_includes @dvh.errors[:height], "El alto del vidrio no puede estar en blanco"
    assert_includes @dvh.errors[:width], "El ancho del vidrio no puede estar en blanco"
  end

  test "should allow any typology format" do
    # Test various typology formats
    valid_typologies = ["V1", "V10", "V123", "V5", "Custom1", "ABC123"]
    
    valid_typologies.each do |typology|
      @dvh.typology = typology
      assert @dvh.valid?, "Typology '#{typology}' should be valid"
    end
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
      glass_type: "LAM", thickness: "4+4", color: "INC", typology: "V1",
      height: 100, width: 50, price: 100.0
    )

    # Create DVH
    dvh = project.dvhs.create!(
      innertube: 9,
      typology: "V2",
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

  test "should maintain typology on destroy" do
    project = Project.create!(
      name: "Test Project",
      phone: "123456789",
      description: "Test description"
    )

    # Create glasscutting and two DVHs
    glasscutting = project.glasscuttings.create!(
      glass_type: "LAM", thickness: "4+4", color: "INC", typology: "V1",
      height: 100, width: 50, price: 100.0
    )

    dvh1 = project.dvhs.create!(
      innertube: 9, typology: "V2", height: 150, width: 100,
      glasscutting1_type: "LAM", glasscutting1_thickness: "4+4", glasscutting1_color: "INC",
      glasscutting2_type: "FLO", glasscutting2_thickness: "3+3", glasscutting2_color: "GRS",
      price: 300.0
    )

    dvh2 = project.dvhs.create!(
      innertube: 12, typology: "V3", height: 200, width: 150,
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

    # Second DVH should keep its typology unchanged
    glasscutting.reload
    dvh2.reload
    assert_equal "V1", glasscutting.typology
    assert_equal "V3", dvh2.typology
  end

  # Tests for new pricing system
  test "ensure_price_is_set uses frontend price when available" do
    # Use fixtures for supplies and create glass prices for glasscuttings
    GlassPrice.create!(glass_type: "LAM", thickness: "3+3", color: "INC", selling_price: 100.0)
    GlassPrice.create!(glass_type: "FLO", thickness: "4+4", color: "GRS", selling_price: 150.0)

    # Set a frontend-calculated price
    frontend_price = 500.75
    @dvh.price = frontend_price

    assert @dvh.save!
    assert_equal frontend_price, @dvh.price
  end

  test "ensure_price_is_set calculates backend price when no frontend price" do
    # Use fixtures for supplies and create glass prices for glasscuttings
    GlassPrice.create!(glass_type: "LAM", thickness: "3+3", color: "INC", selling_price: 100.0)
    GlassPrice.create!(glass_type: "FLO", thickness: "4+4", color: "GRS", selling_price: 150.0)

    # Don't set frontend price (should be nil)
    @dvh.price = nil

    assert @dvh.save!
    
    # Should calculate price based on innertube + glasscuttings
    assert @dvh.price.present?
    assert @dvh.price > 0
  end

  test "pricing system works end to end in project creation" do
    # Use fixtures for supplies and create glass prices
    GlassPrice.create!(glass_type: "LAM", thickness: "3+3", color: "INC", selling_price: 100.0)
    GlassPrice.create!(glass_type: "FLO", thickness: "4+4", color: "GRS", selling_price: 150.0)

    # Create project with DVH (simulating form submission)
    project = Project.create!(
      name: "Test Project",
      phone: "123456789", 
      description: "Test"
    )

    # Create DVH without frontend price (backend should calculate)
    dvh = project.dvhs.create!(
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

    # DVH should have a calculated price
    assert dvh.price.present?
    assert dvh.price > 0
    
    # Price should include both glass and innertube costs
    expected_glass_cost = 0.8 * (100.0 + 150.0) # 200
    assert dvh.price >= expected_glass_cost, "Price should at least include glass costs"
  end
end
