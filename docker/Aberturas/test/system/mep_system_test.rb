require "application_system_test_case"

class MepSystemTest < ApplicationSystemTestCase
  def setup
    AppConfig.delete_all
    Supply.delete_all
    GlassPrice.delete_all
  end

  test "user can set MEP rate and see supplies updated" do
    # Create some supplies first
    Supply.create!(name: "Test Supply 1", price_usd: 10.0, price_peso: 0.0)
    Supply.create!(name: "Test Supply 2", price_usd: 25.0, price_peso: 0.0)

    visit glass_prices_path

    # Find and fill the MEP rate input
    fill_in "mep_rate", with: "1200"
    click_button "Aplicar"

    # Should see success message
    assert_text "Dólar MEP actualizado correctamente"

    # Should see updated peso prices in the supplies table
    within("#supplies_table") do
      assert_text "$12,000.00" # 10.0 * 1200
      assert_text "$30,000.00" # 25.0 * 1200
    end
  end

  test "user can update general percentage and see glass prices updated" do
    # Create some glass prices
    GlassPrice.create!(glass_type: "LAM", thickness: "3+3", color: "INC", buying_price: 100.0, percentage: 10.0)
    GlassPrice.create!(glass_type: "LAM", thickness: "4+4", color: "BLS", buying_price: 200.0, percentage: 15.0)

    visit glass_prices_path

    # Find and fill the percentage input
    fill_in "percentage", with: "25"
    click_button "Aplicar"

    # Should see success message
    assert_text "Porcentaje general actualizado correctamente"

    # Should see updated selling prices in the glass prices table
    within("#glass_prices_table") do
      assert_text "$125.00" # 100 * 1.25
      assert_text "$250.00" # 200 * 1.25
    end
  end

  test "user sees validation errors for invalid MEP rate" do
    visit glass_prices_path

    # Try to set zero MEP rate
    fill_in "mep_rate", with: "0"
    click_button "Aplicar"

    # Should see error message
    assert_text "El valor del dólar MEP debe ser mayor a 0"
  end

  test "user sees validation errors for invalid percentage" do
    visit glass_prices_path

    # Try to set negative percentage
    fill_in "percentage", with: "-10"
    click_button "Aplicar"

    # Should see error message
    assert_text "El porcentaje debe ser mayor o igual a 0"
  end

  test "inline editing of supplies with MEP system" do
    # Set up MEP rate first
    AppConfig.set_mep_rate(1300.0)
    
    # Create a supply
    supply = Supply.create!(name: "Editable Supply", price_usd: 5.0, price_peso: 6500.0)

    visit glass_prices_path

    # Find the supply row and edit button
    within("#supply_row_#{supply.id}") do
      # Should show current peso price
      assert_text "$6,500.00"
      
      # Click edit to show inline form
      click_button "Editar"
      
      # Fill new USD price
      fill_in "supply_price_usd", with: "8.0"
      
      # Submit the form
      find("input[type='submit'][value='✓']").click
    end

    # Should see updated peso price automatically calculated
    within("#supply_row_#{supply.id}") do
      assert_text "$10,400.00" # 8.0 * 1300
    end
  end

  test "MEP rate persists across page reloads" do
    visit glass_prices_path

    # Set MEP rate
    fill_in "mep_rate", with: "1450"
    click_button "Aplicar"

    # Reload page
    visit glass_prices_path

    # MEP rate input should show the stored value
    assert_field "mep_rate", with: "1450.0"
  end

  test "supplies table shows both USD and peso prices" do
    # Set MEP rate
    AppConfig.set_mep_rate(1200.0)
    
    # Create supply
    Supply.create!(name: "Dual Price Supply", price_usd: 15.75, price_peso: 18900.0)

    visit glass_prices_path

    within("#supplies_table") do
      # Should show both currencies
      assert_text "US$15.75"
      assert_text "$18,900.00"
    end
  end

  test "glass prices percentage update affects multiple rows" do
    # Create multiple glass prices
    GlassPrice.create!(glass_type: "LAM", thickness: "3+3", color: "INC", buying_price: 150.0, percentage: 20.0)
    GlassPrice.create!(glass_type: "LAM", thickness: "4+4", color: "BLS", buying_price: 200.0, percentage: 15.0)
    GlassPrice.create!(glass_type: "LAM", thickness: "5+5", color: "GRY", buying_price: 250.0, percentage: 10.0)

    visit glass_prices_path

    # Update percentage
    fill_in "percentage", with: "30"
    click_button "Aplicar"

    # All glass prices should show 30% now
    within("#glass_prices_table") do
      # Check that percentage columns show 30.0%
      assert_text "30.0%", count: 3
      
      # Check calculated selling prices
      assert_text "$195.00" # 150 * 1.30
      assert_text "$260.00" # 200 * 1.30  
      assert_text "$325.00" # 250 * 1.30
    end
  end
end
