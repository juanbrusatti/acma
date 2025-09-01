require "application_system_test_case"

class DvhsTest < ApplicationSystemTestCase
  setup do
    @project = projects(:one)
  end

  test "should create dvh from project form" do
    visit new_project_url

    # Ensure the form is visible
    assert_selector "form"

    # Fill in project fields
    fill_in "Nombre", with: "Proyecto SystemTest"
    fill_in "Teléfono", with: "123456"

    # Crear el proyecto básico
    click_on "Crear proyecto"

    # Esperar el redirect a la página de edición o detalle
    assert_text "Proyecto creado exitosamente."
    # Verificar que el campo de nombre tenga el valor correcto
    assert_field "Nombre", with: "Proyecto SystemTest"

    # Ahora sí, agregar un DVH
    find('#add-dvh', visible: true, wait: 5).click

    within "#dvhs-wrapper" do
      assert_selector ".dvh-fields", wait: 5

      find("select[name='project[dvhs_attributes][][innertube]'").select("12")
      find("input.typology-number-input").fill_in with: "1"
      find("input[name='project[dvhs_attributes][][height]'").fill_in with: "120"
      find("input[name='project[dvhs_attributes][][width]'").fill_in with: "100"
      find(".glasscutting1-type-select").select("LAM")
      find(".glasscutting1-thickness-select").select("3+3")
      find(".glasscutting1-color-select").select("INC")
      find(".glasscutting2-type-select").select("LAM")
      find(".glasscutting2-thickness-select").select("3+3")
      find(".glasscutting2-color-select").select("INC")
      find("select[name='project[dvhs_attributes][][type_opening]'").select("PVC")
      click_on "Confirmar"
    end

    # Esperar a que el formulario de DVH desaparezca (confirmado)
    assert_no_selector ".dvh-fields", wait: 5

    # Guardar el proyecto con el DVH agregado
    click_on "Guardar como presupuesto"

    # Verificaciones finales
    assert_text "Proyecto creado exitosamente."
    # Permitir ambos posibles destinos tras guardar
    assert_match %r{^/projects}, current_path
  end
end
