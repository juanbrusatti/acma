require "application_system_test_case"

class DvhsTest < ApplicationSystemTestCase
  setup do
    @project = projects(:one)
  end

  test "should create dvh from project form" do
    visit new_project_url

    # Fill in required project fields
    fill_in "Nombre", with: "Proyecto SystemTest"
    select "pendiente", from: "Estado"

    # Add a DVH
    click_on "Agregar DVH"
    within "#dvhs-wrapper" do
      fill_in "Camara", with: "1"
      fill_in "Ubicación", with: "Obra Norte"
      fill_in "Alto (mm)", with: "120"
      fill_in "Ancho (mm)", with: "100"
      fill_in "Tipo vidrio 1", with: "Incoloro"
      fill_in "Tipo vidrio 2", with: "Incoloro"
    end

    click_on "Crear Proyecto"

    assert_text "Proyecto creado correctamente"
    assert_text "Obra Norte"
    assert_text "Incoloro"
  end
end 