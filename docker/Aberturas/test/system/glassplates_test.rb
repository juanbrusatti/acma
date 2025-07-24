require "application_system_test_case"

class GlassplatesTest < ApplicationSystemTestCase
  setup do
    @glassplate = glassplates(:complete_sheet)
    @scrap = glassplates(:scrap)
  end

  test "visiting the index" do
    visit glassplates_url
    assert_selector "h1", text: "Gestión de Stock"

    # Check for stock summary cards
    assert_selector ".text-2xl", text: "10" # total_sheets from fixture
    assert_selector ".text-2xl", text: "3"  # total_scraps from fixtures
  end

  test "should create complete sheet glassplate" do
    visit glassplates_url
    click_on "Agregar Material"

    # Fill in the form
    select "Incoloro", from: "Tipo"
    fill_in "Espesor", with: "4mm"
    select "transparente", from: "Color"
    fill_in "Ancho (mm)", with: "600"
    fill_in "Alto (mm)", with: "400"
    fill_in "Medidas Estándar", with: "600x400mm"
    fill_in "Cantidad", with: "5"
    fill_in "Ubicación", with: "Estante A"
    select "disponible", from: "Estado"
    check "Es un sobrante/recorte"
    uncheck "Es un sobrante/recorte" # Make sure it's unchecked for complete sheet

    click_on "Guardar Material"

    assert_text "Material agregado exitosamente al stock"
    assert_current_path glassplates_path
  end

  test "should create scrap glassplate" do
    visit glassplates_url
    click_on "Agregar Material"

    # Fill in the form for scrap
    select "Templado", from: "Tipo"
    fill_in "Espesor", with: "6mm"
    select "azul", from: "Color"
    fill_in "Ancho (mm)", with: "300"
    fill_in "Alto (mm)", with: "200"
    fill_in "Medidas Estándar", with: "300x200mm"
    fill_in "Cantidad", with: "1"
    fill_in "Ubicación", with: "Rack de sobrantes"
    select "disponible", from: "Estado"
    check "Es un sobrante/recorte"

    click_on "Guardar Material"

    assert_text "Material agregado exitosamente al stock"
    assert_current_path glassplates_path
  end

  test "should update glassplate" do
    visit glassplates_url

    # Find and click edit button for the first glassplate
    within "tbody tr:first-child" do
      find("a[href*='edit']").click
    end

    # Update the form
    fill_in "Cantidad", with: "15"
    fill_in "Ubicación", with: "Estante Nuevo"
    select "reservado", from: "Estado"

    click_on "Actualizar Material"

    assert_text "Material actualizado exitosamente"
    assert_current_path glassplates_path
  end

  test "should destroy glassplate" do
    visit glassplates_url

    # Find and click delete button for the first glassplate
    within "tbody tr:first-child" do
      accept_confirm do
        find("a[href*='delete'], a[data-turbo-method='delete']").click
      end
    end

    assert_text "Material eliminado exitosamente"
    assert_current_path glassplates_path
  end

  test "should switch between tabs" do
    visit glassplates_url

    # Initially should be on "Planchas Completas" tab
    assert_selector "button.active", text: "Planchas Completas"
    assert_selector "#planchas-tab:not(.hidden)"
    assert_selector "#sobrantes-tab.hidden"

    # Click on "Sobrantes" tab
    click_on "Sobrantes (Recortes)"

    # Should switch to sobrantes tab
    assert_selector "button.active", text: "Sobrantes (Recortes)"
    assert_selector "#sobrantes-tab:not(.hidden)"
    assert_selector "#planchas-tab.hidden"

    # Click back to "Planchas Completas" tab
    click_on "Planchas Completas"

    # Should switch back
    assert_selector "button.active", text: "Planchas Completas"
    assert_selector "#planchas-tab:not(.hidden)"
    assert_selector "#sobrantes-tab.hidden"
  end

  test "should display complete sheets in first tab" do
    visit glassplates_url

    # Should show complete sheets in the first tab
    assert_selector "#planchas-tab table tbody tr", count: 2 # complete_sheet and two fixtures
    assert_selector "#planchas-tab", text: "Incoloro"
    assert_selector "#planchas-tab", text: "4mm"
  end

  test "should display scraps in second tab" do
    visit glassplates_url

    # Click on scraps tab
    click_on "Sobrantes (Recortes)"

    # Should show scraps in the second tab
    assert_selector "#sobrantes-tab table tbody tr", count: 3 # scrap, available, reserved fixtures
    assert_selector "#sobrantes-tab", text: "Disponible"
    assert_selector "#sobrantes-tab", text: "Reservado"
  end

  test "should show validation errors for invalid form" do
    visit glassplates_url
    click_on "Agregar Material"

    # Try to submit empty form
    click_on "Crear Material"

    # Should show validation errors
    assert_text "error"
    assert_current_path glassplates_path
  end

  test "should navigate back from new form" do
    visit glassplates_url
    click_on "Agregar Material"

    click_on "Cancelar"

    assert_current_path glassplates_path
  end

  test "should navigate back from edit form" do
    visit glassplates_url

    within "tbody tr:first-child" do
      find("a[href*='edit']").click
    end

    click_on "Cancelar"

    assert_current_path glassplates_path
  end
end
