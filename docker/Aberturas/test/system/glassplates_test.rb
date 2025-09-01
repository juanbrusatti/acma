require "application_system_test_case"

class GlassplatesTest < ApplicationSystemTestCase
  setup do
    @glassplate = glassplates(:one)
  end

  test "visiting the index" do
    visit glassplates_url
    assert_selector "h1", text: "Gestión de Stock"

    # Check for stock summary cards
    assert_selector ".text-2xl", text: "10" # total_sheets from fixture
    assert_selector ".text-2xl", text: "3"  # total_scraps from fixtures
  end

  test "should create glassplate" do
    visit glassplates_url
    click_on "Agregar plancha"

    select "LAM", from: "Tipo"
    # Forzar evento JS para que se llenen los selects dependientes
    page.execute_script("document.getElementById('glassplate_glass_type').dispatchEvent(new Event('change', { bubbles: true }));")
    # Esperar a que JS agregue la opción "4+4"
    assert_selector "#glassplate_thickness option:not([value=''])", text: "4+4", wait: 5
    select "4+4", from: "Espesor"
    assert_selector "#glassplate_color option:not([value=''])", text: "INC", wait: 5
    select "INC", from: "Color"
    fill_in "Ancho (mm)", with: "600"
    fill_in "Alto (mm)", with: "400"
    fill_in "Cantidad", with: "5"

    click_on "Guardar Material"
    assert_text "Material agregado exitosamente al stock", wait: 5
    assert_current_path glassplates_path, ignore_query: true
  end

  test "should create scrap glassplate" do
    visit glassplates_url
    click_on "Agregar plancha"

    select "FLO", from: "Tipo"
    page.execute_script("document.getElementById('glassplate_glass_type').dispatchEvent(new Event('change', { bubbles: true }));")
    assert_selector "#glassplate_thickness option:not([value=''])", text: "5mm", wait: 5
    select "5mm", from: "Espesor"
    assert_selector "#glassplate_color option:not([value=''])", text: "INC", wait: 5
    select "INC", from: "Color"
    fill_in "Ancho (mm)", with: "300"
    fill_in "Alto (mm)", with: "200"
    fill_in "Cantidad", with: "1"

    click_on "Guardar Material"
    assert_text "Material agregado exitosamente al stock", wait: 5
    assert_current_path glassplates_path, ignore_query: true
  end

  test "should update glassplate" do
    visit glassplates_url

    within "tbody tr:first-child" do
      find("a[href*='edit']").click
    end

    fill_in "Cantidad", with: "15"
    click_on "Guardar Material"
    assert_text "Material actualizado exitosamente", wait: 5
    assert_current_path glassplates_path, ignore_query: true
  end

  test "should destroy glassplate" do
    visit glassplates_url

    within "tbody tr:first-child" do
      find("a[data-method='delete'], a[data-turbo-method='delete']").click
    end
    if page.has_button?("Sí, eliminar", wait: 2)
      click_on "Sí, eliminar"
    end
    assert_text "Material eliminado exitosamente", wait: 5
    assert_current_path glassplates_path, ignore_query: true
  end

  test "should switch between tabs" do
    visit glassplates_url

    assert_selector "button", text: "Planchas completas"
    assert_selector "#planchas-tab", visible: true
    assert_selector "#sobrantes-tab", visible: :hidden

    click_on "Retazos"

    assert_selector "button", text: "Retazos"
    assert_selector "#sobrantes-tab", visible: true
    assert_selector "#planchas-tab", visible: :hidden
  end

  test "should display complete sheets in first tab" do
    visit glassplates_url

    assert_selector "#planchas-tab table tbody tr", wait: 5
    assert_text "INC"
    assert_text "4+4"
  end

  test "should display scraps in second tab" do
    visit glassplates_url

    click_on "Retazos"

    assert_selector "#sobrantes-tab table tbody tr"
    assert_text "Disponible"
    assert_text "Reservado"
  end

  test "should show validation errors for invalid form" do
    visit glassplates_url
    click_on "Agregar plancha"

    click_on "Guardar Material"

    assert_text "error"
    # Puede quedar en /glassplates/new tras error
    assert_includes [glassplates_path, new_glassplate_path], page.current_path
  end

  test "should navigate back from new form" do
    visit glassplates_url
    click_on "Agregar plancha"

    click_on "Cancelar"

    assert_current_path glassplates_path, ignore_query: true
  end

  test "should navigate back from edit form" do
    visit glassplates_url

    within "tbody tr:first-child" do
      find("a[href*='edit']").click
    end

    click_on "Cancelar"

    assert_current_path glassplates_path, ignore_query: true
  end
end
