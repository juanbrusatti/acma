require "application_system_test_case"

class GlasscuttingsTest < ApplicationSystemTestCase
  setup do
    @project = projects(:one)
  end

  test "should create glasscutting from project form" do
    visit new_project_url

    # Fill in required project fields
    fill_in "Nombre", with: "Proyecto SystemTest"
    select "pendiente", from: "Estado"

    # Add a Glasscutting
    click_on "Agregar vidrio simple"
    within "#glasscuttings-wrapper" do
      fill_in "Tipo de vidrio", with: "Laminado"
      fill_in "Grosor", with: "4mm"
      fill_in "Alto (mm)", with: "120"
      fill_in "Ancho (mm)", with: "100"
      fill_in "Color", with: "Transparente"
      fill_in "Ubicación", with: "Depósito"
    end

    click_on "Crear Proyecto"

    assert_text "Proyecto creado correctamente"
    assert_text "Laminado"
    assert_text "Transparente"
  end
end 