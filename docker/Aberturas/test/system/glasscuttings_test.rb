require "application_system_test_case"

class GlasscuttingsTest < ApplicationSystemTestCase
  setup do
    @project = projects(:one)
  end

  test "should create glasscutting from project form" do
    visit new_project_url

    # Fill in required project fields
    fill_in "Nombre", with: "Proyecto SystemTest"
    # You can uncomment if status is required
    # select "pendiente", from: "Estado"
    fill_in "Teléfono", with: "1234456"

    # Add a simple glass
    click_on "Agregar vidrio simple"

    within "#glasscuttings-wrapper" do
      # Verify form presence and fill in the fields
      assert_selector ".glasscutting-fields", wait: 5
      
      find(".glass-type-select").select("LAM")
      sleep(0.5) # Wait for JavaScript to populate dependent selects
      find(".glass-thickness-select").select("3+3")
      find(".glass-color-select").select("INC")
      find(".typology-number-input").fill_in with: "1"  # This will create "V1"
      find("input[name='project[glasscuttings_attributes][][height]']").fill_in with: "120"
      find("input[name='project[glasscuttings_attributes][][width]']").fill_in with: "100"
    end

    # Submit the form
    click_on "Guardar como presupuesto"

    # Verify that everything was saved correctly
    assert_text "Proyecto creado exitosamente."
    assert_text "Proyecto SystemTest"  # Name of the project we created
    assert_current_path projects_path
  end
end
