require "test_helper"

class PricingIntegrationTest < ActionDispatch::IntegrationTest
  def setup
    # Use fixtures for supplies and setup additional data
    setup_glass_prices
  end

  # Test removed - we don't test supply creation UI since it's not used

  test "backend price calculation fallback when frontend prices missing" do
    # Create project without frontend prices
    post projects_url, params: {
      project: {
        name: "Backend Calculation Test",
        phone: "987654321",
        description: "Test backend price calculation",
        status: "Pendiente",
        address: "Test Address",
        glasscuttings_attributes: {
          "0" => {
            glass_type: "LAM",
            thickness: "3+3",
            color: "INC",
            location: "DINTEL",
            height: 1000,
            width: 800
            # No price - should trigger backend calculation
          }
        },
        dvhs_attributes: {
          "0" => {
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
            # No price - should trigger backend calculation
          }
        }
      }
    }

    assert_response :redirect
    project = Project.last

    # All components should have calculated prices
    glasscutting = project.glasscuttings.first
    assert glasscutting.price.present?, "Glasscutting should have calculated price"
    assert glasscutting.price > 0, "Glasscutting price should be positive"

    dvh = project.dvhs.first
    assert dvh.price.present?, "DVH should have calculated price"
    assert dvh.price > 0, "DVH price should be positive"

    # Project totals should be calculated from component prices
    expected_subtotal = glasscutting.price + dvh.price
    assert_equal expected_subtotal, project.subtotal, "Project subtotal should sum component prices"
  end

  # Test removed - we don't test supply creation UI since it's not used

  test "MEP rate changes affect innertube pricing" do
    initial_rate = 1200.0
    AppConfig.set_mep_rate(initial_rate)
    
    # Update all supply peso prices with the initial rate
    Supply.all.each { |supply| supply.update_peso_price_from_usd!(initial_rate) }
    
    initial_price = AppConfig.calculate_innertube_price_per_meter(6)
    assert initial_price > 0, "Should calculate initial price"

    # Change MEP rate and update all supply peso prices
    new_rate = 1500.0
    AppConfig.set_mep_rate(new_rate)
    Supply.all.each { |supply| supply.update_peso_price_from_usd!(new_rate) }
    
    new_price = AppConfig.calculate_innertube_price_per_meter(6)
    
    # Price should increase proportionally
    expected_ratio = new_rate / initial_rate
    actual_ratio = new_price / initial_price  
    assert_in_delta expected_ratio, actual_ratio, 0.01, "Price should change proportionally with MEP rate"
  end

  test "supply price changes affect innertube pricing" do
    # Get initial price
    initial_price = AppConfig.calculate_innertube_price_per_meter(6)
    
    # Change supply prices
    Supply.find_by(name: "Tamiz").update!(price_usd: 10.0) # Double the price
    
    new_price = AppConfig.calculate_innertube_price_per_meter(6)
    
    # Price should increase
    assert new_price > initial_price, "Price should increase when supply prices increase"
  end

  test "glass price changes affect glasscutting pricing" do
    # Create glasscutting without frontend price
    project = Project.create!(
      name: "Glass Price Test",
      phone: "111222333",
      description: "Test glass price changes"
    )

    glasscutting = project.glasscuttings.build(
      glass_type: "LAM",
      thickness: "3+3",
      color: "INC",
      location: "DINTEL",
      height: 1000,
      width: 800
    )

    # Get initial calculated price
    glasscutting.save!
    initial_price = glasscutting.price

    # Change glass price
    glass_price = GlassPrice.find_by(glass_type: "LAM", thickness: "3+3", color: "INC")
    glass_price.update!(selling_price: glass_price.selling_price * 2) # Double the price

    # Create new glasscutting with same specs
    new_glasscutting = project.glasscuttings.create!(
      glass_type: "LAM",
      thickness: "3+3",
      color: "INC",
      location: "JAMBA_I",
      height: 1000,
      width: 800
    )

    # New glasscutting should have higher price
    assert new_glasscutting.price > initial_price, "Price should increase when glass prices increase"
  end

  private

  def setup_glass_prices
    GlassPrice.create!(glass_type: "LAM", thickness: "3+3", color: "INC", selling_price: 100.0)
    GlassPrice.create!(glass_type: "LAM", thickness: "4+4", color: "INC", selling_price: 120.0)
    GlassPrice.create!(glass_type: "FLO", thickness: "4+4", color: "GRS", selling_price: 150.0)
    GlassPrice.create!(glass_type: "FLO", thickness: "5mm", color: "INC", selling_price: 80.0)
    GlassPrice.create!(glass_type: "COL", thickness: "5+5", color: "BRC", selling_price: 200.0)
  end
end
