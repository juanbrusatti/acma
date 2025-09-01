require "application_system_test_case"

class GlasscuttingsTest < ApplicationSystemTestCase
  setup do
    @project = projects(:one)
  end

  test "should create glasscutting from project form" do
    visit new_project_url

    # Fill in required project fields
    fill_in "Nombre", with: "Proyecto SystemTest"
    fill_in "Teléfono", with: "1234456"

    # Crear el proyecto básico
    click_on "Crear proyecto"

    # Esperar el redirect a la página de edición o detalle
    assert_text "Proyecto creado exitosamente."
    assert_field "Nombre", with: "Proyecto SystemTest"

    # Agregar un vidrio simple
    find('#add-glasscutting', visible: true, wait: 5).click

    within "#glasscuttings-wrapper" do
      assert_selector ".glasscutting-fields", wait: 5
      find(".glass-type-select").select("LAM")
      sleep(0.5)
      find(".glass-thickness-select").select("3+3")
      find(".glass-color-select").select("INC")
      find(".typology-number-input").fill_in with: "1"
      find("input[name='project[glasscuttings_attributes][][height]']").fill_in with: "120"
      find("input[name='project[glasscuttings_attributes][][width]']").fill_in with: "100"
      # Si hay select de tipo de apertura, completarlo
      begin
        find("select[name='project[glasscuttings_attributes][][type_opening]']").select("PVC")
      rescue Capybara::ElementNotFound
      end
      click_on "Confirmar"
    end

    # Esperar a que el formulario de glasscutting desaparezca (confirmado)
    assert_no_selector ".glasscutting-fields", wait: 5

    # Guardar el proyecto con el vidrio agregado
    click_on "Guardar como presupuesto"

    # Verificaciones finales
    assert_text "Proyecto creado exitosamente."
    assert_match %r{^/projects}, current_path
  end
end
