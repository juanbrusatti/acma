require "test_helper"

class ProjectTest < ActiveSupport::TestCase
  def setup
    @project = projects(:one)
  end

  test "should assign typologies to glasscuttings and dvhs on save" do
    project = Project.create!(
      name: "Test Project",
      phone: "123456789",
      description: "Test description"
    )

    # Create glasscuttings
    glasscutting1 = project.glasscuttings.create!(
      glass_type: "LAM",
      thickness: "4+4",
      color: "INC",
      typology: "V1",
      height: 100,
      width: 50,
      price: 100.0,
      type_opening: "PVC"
    )
    
    glasscutting2 = project.glasscuttings.create!(
      glass_type: "FLO",
      thickness: "3+3",
      color: "GRS",
      typology: "V2",
      height: 200,
      width: 75,
      price: 200.0,
      type_opening: "PVC"
    )

    # Create DVH
    dvh = project.dvhs.create!(
      innertube: 9,
      typology: "V3",
      height: 150,
      width: 100,
      glasscutting1_type: "LAM",
      glasscutting1_thickness: "4+4",
      glasscutting1_color: "INC",
      glasscutting2_type: "FLO",
      glasscutting2_thickness: "3+3",
      glasscutting2_color: "GRS",
      price: 300.0,
      type_opening: "PVC"
    )

    # Trigger typology assignment
    project.save!

    # Reload to get fresh data
    glasscutting1.reload
    glasscutting2.reload
    dvh.reload

    # Assert typologies are assigned correctly
    assert_equal "V1", glasscutting1.typology
    assert_equal "V2", glasscutting2.typology
    assert_equal "V3", dvh.typology
  end

  test "should maintain typologies when glasscutting is deleted" do
    project = Project.create!(
      name: "Test Project",
      phone: "123456789",
      description: "Test description"
    )

    # Create glasscuttings
    glasscutting1 = project.glasscuttings.create!(
      glass_type: "LAM", thickness: "4+4", color: "INC", typology: "V1",
      height: 100, width: 50, price: 100.0, type_opening: "PVC"
    )
    
    glasscutting2 = project.glasscuttings.create!(
      glass_type: "FLO", thickness: "3+3", color: "GRS", typology: "V2",
      height: 200, width: 75, price: 200.0, type_opening: "PVC"
    )

    dvh = project.dvhs.create!(
      innertube: 9, typology: "V3", height: 150, width: 100,
      glasscutting1_type: "LAM", glasscutting1_thickness: "4+4", glasscutting1_color: "INC",
      glasscutting2_type: "FLO", glasscutting2_thickness: "3+3", glasscutting2_color: "GRS",
      price: 300.0,
      type_opening: "PVC"
    )

    project.save!

    # Verify initial typologies
    glasscutting1.reload
    glasscutting2.reload
    dvh.reload
    
    assert_equal "V1", glasscutting1.typology
    assert_equal "V2", glasscutting2.typology
    assert_equal "V3", dvh.typology

    # Delete first glasscutting
    glasscutting1.destroy!

    # Reload remaining items
    glasscutting2.reload
    dvh.reload

    # Assert typologies remain unchanged
    assert_equal "V2", glasscutting2.typology
    assert_equal "V3", dvh.typology
  end

  test "should maintain typologies when dvh is deleted" do
    project = Project.create!(
      name: "Test Project",
      phone: "123456789",
      description: "Test description"
    )

    glasscutting = project.glasscuttings.create!(
      glass_type: "LAM", thickness: "4+4", color: "INC", typology: "V1",
      height: 100, width: 50, price: 100.0, type_opening: "PVC"
    )

    dvh1 = project.dvhs.create!(
      innertube: 9, typology: "V2", height: 150, width: 100,
      glasscutting1_type: "LAM", glasscutting1_thickness: "4+4", glasscutting1_color: "INC",
      glasscutting2_type: "FLO", glasscutting2_thickness: "3+3", glasscutting2_color: "GRS",
      price: 300.0,
      type_opening: "PVC"
    )

    dvh2 = project.dvhs.create!(
      innertube: 12, typology: "V3", height: 200, width: 150,
      glasscutting1_type: "COL", glasscutting1_thickness: "5+5", glasscutting1_color: "BRC",
      glasscutting2_type: "LAM", glasscutting2_thickness: "4+4", glasscutting2_color: "STB",
      price: 400.0,
      type_opening: "PVC"
    )

    project.save!

    # Verify initial typologies
    glasscutting.reload
    dvh1.reload
    dvh2.reload
    
    assert_equal "V1", glasscutting.typology
    assert_equal "V2", dvh1.typology
    assert_equal "V3", dvh2.typology

    # Delete first DVH
    dvh1.destroy!

    # Reload remaining items
    glasscutting.reload
    dvh2.reload

    # Assert typologies remain unchanged
    assert_equal "V1", glasscutting.typology
    assert_equal "V3", dvh2.typology
  end

  # Tests for project pricing system
  test "subtotal uses saved price_without_iva when available" do
    saved_subtotal = 1500.75
    @project.price_without_iva = saved_subtotal
    
    assert_equal saved_subtotal, @project.subtotal
  end

  test "subtotal calculates from components when price_without_iva not saved" do
    # Create a fresh project to avoid fixture pollution
    project = Project.create!(
      name: "Test Project",
      phone: "123456789",
      description: "Test description"
    )
    
    # Ensure no saved price
    project.price_without_iva = nil
    
    # Force glasscutting to use our price by updating after creation
    glasscutting = project.glasscuttings.create!(
      glass_type: "LAM", thickness: "3+3", color: "INC", typology: "V001",
      height: 1000, width: 800, type_opening: "PVC"
    )
    glasscutting.update_column(:price, 100.0)
    
    dvh = project.dvhs.create!(
      innertube: "6", typology: "V001", height: 1000, width: 800,
      glasscutting1_type: "LAM", glasscutting1_thickness: "3+3", glasscutting1_color: "INC",
      glasscutting2_type: "FLO", glasscutting2_thickness: "4+4", glasscutting2_color: "GRS",
      type_opening: "PVC"
    )
    
    # Directly update price column to override calculation
    dvh.update_column(:price, 250.0)
    
    # Reload to make sure we have the updated values
    glasscutting.reload
    dvh.reload
    project.reload
    
    # Use actual calculated prices for assertion
    expected_subtotal = glasscutting.price + dvh.price # Should be 100 + 250 = 350
    assert_equal expected_subtotal, project.subtotal
  end

  test "iva calculates 21% of subtotal" do
    @project.price_without_iva = 1000.0
    expected_iva = 1000.0 * 0.21 # 210.0
    
    assert_equal expected_iva, @project.iva
  end

  test "total calculates subtotal plus iva" do
    @project.price_without_iva = 1000.0
    expected_total = 1000.0 + (1000.0 * 0.21) # 1000 + 210 = 1210
    
    assert_equal expected_total, @project.total
  end

  test "precio_sin_iva alias works correctly" do
    @project.price_without_iva = 800.0
    
    assert_equal @project.subtotal, @project.precio_sin_iva
  end

  test "end to end pricing works with frontend calculated prices" do
    # Create a project with frontend-calculated prices (simulating form submission)
    project = Project.create!(
      name: "Test Project",
      phone: "123456789",
      description: "Test description",
      price: 1210.0,           # Total with IVA from frontend
      price_without_iva: 1000.0 # Subtotal from frontend
    )

    # Create components with frontend-calculated prices
    glasscutting = project.glasscuttings.create!(
      glass_type: "LAM", thickness: "3+3", color: "INC", typology: "V001",
      height: 1000, width: 800, price: 400.0, type_opening: "PVC" # Frontend calculated
    )
    
    dvh = project.dvhs.create!(
      innertube: "6", typology: "V001", height: 1000, width: 800,
      glasscutting1_type: "LAM", glasscutting1_thickness: "3+3", glasscutting1_color: "INC",
      glasscutting2_type: "FLO", glasscutting2_thickness: "4+4", glasscutting2_color: "GRS",
      price: 600.0, # Frontend calculated
      type_opening: "PVC"
    )

    # Project should use saved prices (not recalculate)
    assert_equal 1000.0, project.subtotal
    assert_equal 210.0, project.iva
    assert_equal 1210.0, project.total
    
    # Components should have their frontend prices
    assert_equal 400.0, glasscutting.price
    assert_equal 600.0, dvh.price
  end

  test "pricing works when only components have frontend prices but project does not" do
    # Project without saved totals
    project = Project.create!(
      name: "Test Project",
      phone: "123456789",
      description: "Test description"
      # No price or price_without_iva set
    )

    # Components with frontend prices
    glasscutting = project.glasscuttings.create!(
      glass_type: "LAM", thickness: "3+3", color: "INC", typology: "V001",
      height: 1000, width: 800, price: 300.0, type_opening: "PVC"
    )
    
    dvh = project.dvhs.create!(
      innertube: "6", typology: "V001", height: 1000, width: 800,
      glasscutting1_type: "LAM", glasscutting1_thickness: "3+3", glasscutting1_color: "INC",
      glasscutting2_type: "FLO", glasscutting2_thickness: "4+4", glasscutting2_color: "GRS",
      price: 500.0,
      type_opening: "PVC"
    )

    # Project should calculate from component prices
    expected_subtotal = 300.0 + 500.0 # 800.0
    expected_iva = 800.0 * 0.21 # 168.0
    expected_total = 800.0 + 168.0 # 968.0
    
    assert_equal expected_subtotal, project.subtotal
    assert_equal expected_iva, project.iva
    assert_equal expected_total, project.total
  end

  test "pricing works with mixed frontend and backend calculated prices" do
    # Use fixtures for supplies and create glass prices
    GlassPrice.create!(glass_type: "LAM", thickness: "3+3", color: "INC", selling_price: 100.0)
    GlassPrice.create!(glass_type: "FLO", thickness: "4+4", color: "GRS", selling_price: 150.0)

    project = Project.create!(
      name: "Test Project",
      phone: "123456789",
      description: "Test description"
    )

    # Glasscutting with frontend price
    glasscutting = project.glasscuttings.create!(
      glass_type: "LAM", thickness: "3+3", color: "INC", typology: "V001",
      height: 1000, width: 800, price: 333.33, type_opening: "PVC" # Frontend calculated
    )
    
    # DVH without frontend price (should be calculated by backend)
    dvh = project.dvhs.create!(
      innertube: "6", typology: "V001", height: 1000, width: 800,
      glasscutting1_type: "LAM", glasscutting1_thickness: "3+3", glasscutting1_color: "INC",
      glasscutting2_type: "FLO", glasscutting2_thickness: "4+4", glasscutting2_color: "GRS",
      type_opening: "PVC"
      # No price set - should trigger backend calculation
    )

    # Glasscutting should have frontend price
    assert_equal 333.33, glasscutting.price
    
    # DVH should have backend-calculated price
    assert dvh.price.present?
    assert dvh.price > 0
    
    # Project totals should include both
    expected_subtotal = glasscutting.price + dvh.price
    assert_equal expected_subtotal, project.subtotal
  end
end
