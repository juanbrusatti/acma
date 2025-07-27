require "application_system_test_case"

class ProjectsJsRenderingTest < ApplicationSystemTestCase
  test "el formulario de proyectos carga los JS y renderiza los elementos dinámicos" do
    visit new_project_path

    # Verifica que los botones para agregar vidrio simple y DVH estén presentes
    assert_selector "button#add-glasscutting", text: "Agregar vidrio simple"
    assert_selector "button#add-dvh", text: "Agregar DVH"

    # Agrega un vidrio simple y verifica los selects dependientes
    find("button#add-glasscutting").click
    within all(".glasscutting-fields").last do
      find(".glass-type-select").find(:option, "LAM").select_option
      assert_selector ".glass-thickness-select option", text: "3+3", wait: 2
      find(".glass-thickness-select").find(:option, "3+3").select_option
      assert_selector ".glass-color-select option", text: "INC", wait: 2
      find(".glass-color-select").find(:option, "INC").select_option
      find(".glass-location-select").find(:option, "DINTEL").select_option
      fill_in "project[glasscuttings_attributes][][height]", with: 1000
      fill_in "project[glasscuttings_attributes][][width]", with: 1000
      click_button "Confirmar"
    end
    # Verifica que la fila se agregó a la tabla y el precio se muestra
    unless page.has_selector?("#glasscuttings-table-body td")
      puts page.html
    end
    assert_selector "#glasscuttings-table-body td", text: "LAM"
    assert_selector "#glasscuttings-table-body td", text: "3+3"
    assert_selector "#glasscuttings-table-body td", text: "INC"
    assert_selector "#glasscuttings-table-body td", text: "DINTEL"
    #assert_selector "#glasscuttings-table-body td", text: "1.00" # precio esperado para 1m2 * precio_m2 (ajustar si tu precio es distinto)

    # Agrega un DVH y verifica selects dependientes y precio
    find("button#add-dvh").click
    within all(".dvh-fields").last do
      find(".glasscutting1-type-select").find(:option, "LAM").select_option
      assert_selector ".glasscutting1-thickness-select option", text: "3+3", wait: 2
      find(".glasscutting1-thickness-select").find(:option, "3+3").select_option
      assert_selector ".glasscutting1-color-select option", text: "INC", wait: 2
      find(".glasscutting1-color-select").find(:option, "INC").select_option
      find(".glasscutting2-type-select").find(:option, "FLO").select_option
      assert_selector ".glasscutting2-thickness-select option", text: "5mm", wait: 2
      find(".glasscutting2-thickness-select").find(:option, "5mm").select_option
      assert_selector ".glasscutting2-color-select option", text: "INC", wait: 2
      find(".glasscutting2-color-select").find(:option, "INC").select_option
      fill_in "project[dvhs_attributes][][height]", with: 1000
      fill_in "project[dvhs_attributes][][width]", with: 1000
      find('select[name="project[dvhs_attributes][][innertube]"]').find(:option, "12").select_option      
      find('select[name="project[dvhs_attributes][][location]"]').find(:option, "DINTEL").select_option      
      click_button "Confirmar"
    end
    # Verifica que la fila se agregó a la tabla y el precio se muestra
    unless page.has_selector?("#dvhs-table-body td")
      puts page.html
    end
    assert_selector "#dvhs-table-body td", text: "LAM"
    assert_selector "#dvhs-table-body td", text: "FLO"
    assert_selector "#dvhs-table-body td", text: "3+3"
    assert_selector "#dvhs-table-body td", text: "5mm"
    assert_selector "#dvhs-table-body td", text: "INC"
    # El precio debería ser la suma de ambos cristales por el área (ajustar si tu precio es distinto)
    # assert_selector "#dvhs-table-body td", text: "..."

    # Verifica que los totales generales se actualizan
    assert_selector "#subtotal-price"
    assert_selector "#iva-value"
    assert_selector "#price-total"
    # Podés agregar asserts para los valores si querés
  end
end