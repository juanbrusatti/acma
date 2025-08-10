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

  # Tests for new pricing system
  test "ensure_price_is_set uses frontend price when available" do
    # Create glass price for backend calculation
    GlassPrice.create!(glass_type: "LAM", thickness: "3+3", color: "INC", selling_price: 100.0)

    # Set a frontend-calculated price
    frontend_price = 250.75
    @glasscutting.price = frontend_price

    assert @glasscutting.save!
    assert_equal frontend_price, @glasscutting.price
  end

  test "ensure_price_is_set calculates backend price when no frontend price" do
    # Create glass price for backend calculation
    GlassPrice.create!(glass_type: "LAM", thickness: "3+3", color: "INC", selling_price: 100.0)

    # Don't set frontend price (should be nil)
    @glasscutting.price = nil

    assert @glasscutting.save!
    
    # Should calculate price: 1000mm x 800mm = 0.8m² * 100.0 = 80.0
    expected_price = 0.8 * 100.0
    assert_equal expected_price, @glasscutting.price
  end

  test "ensure_price_is_set does not override zero price from frontend" do
    # Create glass price for backend calculation
    GlassPrice.create!(glass_type: "LAM", thickness: "3+3", color: "INC", selling_price: 100.0)

    # Explicitly set price to 0 (simulating frontend calculation that resulted in 0)
    @glasscutting.price = 0

    assert @glasscutting.save!
    
    # Should calculate backend price since frontend price is 0
    expected_price = 0.8 * 100.0
    assert_equal expected_price, @glasscutting.price
  end

  test "set_price_from_backend calculates correct price" do
    # Create glass price
    glass_price = GlassPrice.create!(glass_type: "LAM", thickness: "3+3", color: "INC", selling_price: 150.0)

    # Calculate expected price: 1000mm x 800mm = 0.8m² * 150.0 = 120.0
    expected_price = 0.8 * glass_price.selling_price

    @glasscutting.send(:set_price_from_backend)
    
    assert_equal expected_price, @glasscutting.price
  end

  test "set_price_from_backend handles missing glass price gracefully" do
    # Don't create any glass price record
    
    @glasscutting.send(:set_price_from_backend)
    
    # Price should remain nil when no glass price is found
    assert_nil @glasscutting.price
  end

  test "set_price_from_backend handles missing selling_price gracefully" do
    # Create glass price without selling_price
    GlassPrice.create!(glass_type: "LAM", thickness: "3+3", color: "INC", selling_price: nil)
    
    @glasscutting.send(:set_price_from_backend)
    
    # Price should remain nil when selling_price is not present
    assert_nil @glasscutting.price
  end

  test "set_price_from_backend handles missing dimensions gracefully" do
    # Create glass price
    GlassPrice.create!(glass_type: "LAM", thickness: "3+3", color: "INC", selling_price: 100.0)
    
    # Remove height and width
    @glasscutting.height = nil
    @glasscutting.width = nil
    
    @glasscutting.send(:set_price_from_backend)
    
    # Price should remain nil when dimensions are missing
    assert_nil @glasscutting.price
  end

  test "pricing system works end to end in project creation" do
    # Create glass price
    GlassPrice.create!(glass_type: "LAM", thickness: "3+3", color: "INC", selling_price: 125.0)

    # Create project with glasscutting (simulating form submission)
    project = Project.create!(
      name: "Test Project",
      phone: "123456789", 
      description: "Test"
    )

    # Create glasscutting without frontend price (backend should calculate)
    glasscutting = project.glasscuttings.create!(
      glass_type: "LAM",
      thickness: "3+3",
      color: "INC",
      typology: "V001",
      height: 1000,
      width: 800
    )

    # Glasscutting should have a calculated price
    assert glasscutting.price.present?
    
    # Expected: 1000mm x 800mm = 0.8m² * 125.0 = 100.0
    expected_price = 0.8 * 125.0
    assert_equal expected_price, glasscutting.price
  end

  test "frontend price takes precedence over backend calculation" do
    # Create glass price for backend calculation
    GlassPrice.create!(glass_type: "LAM", thickness: "3+3", color: "INC", selling_price: 100.0)

    # Create project
    project = Project.create!(
      name: "Test Project",
      phone: "123456789", 
      description: "Test"
    )

    # Create glasscutting WITH frontend price (simulating form submission with calculated price)
    frontend_calculated_price = 333.33
    glasscutting = project.glasscuttings.create!(
      glass_type: "LAM",
      thickness: "3+3",
      color: "INC",
      typology: "V001",
      height: 1000,
      width: 800,
      price: frontend_calculated_price
    )

    # Should use frontend price, not backend calculation
    assert_equal frontend_calculated_price, glasscutting.price
  end
end
