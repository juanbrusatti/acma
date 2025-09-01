require "application_system_test_case"

class MepSystemTest < ApplicationSystemTestCase
  def setup
    AppConfig.delete_all
    Supply.delete_all
    GlassPrice.delete_all
  end

  test "user can set MEP rate and see supplies updated" do
    Supply.create!(name: "Test Supply 1", price_usd: 10.0, price_peso: 0.0)
    Supply.create!(name: "Test Supply 2", price_usd: 25.0, price_peso: 0.0)

    visit glass_prices_path
    save_and_open_screenshot

    fill_in "mep_rate", with: "1200"
    accept_alert do
      click_button "Aplicar"
    end

    assert_text "Dólar MEP actualizado correctamente", wait: 5
    within("#supplies_table") do
      assert_text "$12.000,00"
      assert_text "$30.000,00"
    end
  end

  test "user can update general percentage and see glass prices updated" do
    GlassPrice.create!(glass_type: "LAM", thickness: "3+3", color: "INC", buying_price: 100.0, percentage: 10.0)
    GlassPrice.create!(glass_type: "LAM", thickness: "4+4", color: "BLS", buying_price: 200.0, percentage: 15.0)

    visit glass_prices_path
    save_and_open_screenshot

    fill_in "percentage", with: "25"
    accept_confirm do
      click_button "Aplicar"
    end

    assert_text "Porcentaje general actualizado correctamente", wait: 5
    within("#glass_prices_table") do
      assert_text "$125,00"
      assert_text "$250,00"
    end
  end

  test "user sees validation errors for invalid MEP rate" do
    visit glass_prices_path
    save_and_open_screenshot

    fill_in "mep_rate", with: "0"
    accept_alert do
      click_button "Aplicar"
    end

    assert_text "El valor del dólar MEP debe ser mayor a 0", wait: 5
  end

  test "user sees validation errors for invalid percentage" do
    visit glass_prices_path
    save_and_open_screenshot

    fill_in "percentage", with: "-10"
    accept_alert do
      click_button "Aplicar"
    end

    assert_text "El porcentaje debe ser mayor o igual a 0", wait: 5
  end

  test "inline editing of supplies with MEP system" do
    AppConfig.set_mep_rate(1300.0)
    supply = Supply.create!(name: "Editable Supply", price_usd: 5.0, price_peso: 6500.0)

    visit glass_prices_path
    save_and_open_screenshot

    within("#supplies_table") do
      assert_selector "#supply_row_#{supply.id}", wait: 5
    end
    within("#supply_row_#{supply.id}") do
      assert_text "$6.500,00"
      click_button "Editar"
      fill_in "supply_price_usd", with: "8.0"
      find("input[type='submit'][value='✓']").click
    end

    within("#supply_row_#{supply.id}") do
      assert_text "$10.400,00"
    end
  end

  test "MEP rate persists across page reloads" do
    visit glass_prices_path
    save_and_open_screenshot

    fill_in "mep_rate", with: "1450"
    accept_alert do
      click_button "Aplicar"
    end

    visit glass_prices_path
    save_and_open_screenshot
    assert_field "mep_rate", with: "1450.0"
  end

  test "supplies table shows both USD and peso prices" do
    AppConfig.set_mep_rate(1200.0)
    Supply.create!(name: "Dual Price Supply", price_usd: 15.75, price_peso: 18900.0)

    visit glass_prices_path
    save_and_open_screenshot

    within("#supplies_table") do
      assert_text "US$15,75"
      assert_text "$18.900,00"
    end
  end

  test "glass prices percentage update affects multiple rows" do
    GlassPrice.create!(glass_type: "LAM", thickness: "3+3", color: "INC", buying_price: 150.0, percentage: 20.0)
    GlassPrice.create!(glass_type: "LAM", thickness: "4+4", color: "BLS", buying_price: 200.0, percentage: 15.0)
    GlassPrice.create!(glass_type: "LAM", thickness: "5+5", color: "GRY", buying_price: 250.0, percentage: 10.0)

    visit glass_prices_path
    save_and_open_screenshot

    fill_in "percentage", with: "30"
    accept_confirm do
      click_button "Aplicar"
    end

    within("#glass_prices_table") do
      assert_text "30,0%"
      assert_text "$195,00"
      assert_text "$260,00"
      assert_text "$325,00"
    end
  end
end
