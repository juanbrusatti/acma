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

    # Add a DVH
    click_on "Agregar DVH"

    within "#dvhs-wrapper" do
      # Wait for the DVH row to load
      assert_selector ".dvh-fields", wait: 5

      find("select[name='project[dvhs_attributes][][innertube]']").select("12")

      find("select[name='project[dvhs_attributes][][location]']").select("DINTEL")

      # Fill in height and width using name (since Capybara doesn't find by visible label in this case)
      find("input[name='project[dvhs_attributes][][height]']").fill_in with: "120"
      find("input[name='project[dvhs_attributes][][width]']").fill_in with: "100"

      # Glass 1
      find(".glasscutting1-type-select").select("LAM")
      find(".glasscutting1-thickness-select").select("3+3")
      find(".glasscutting1-color-select").select("INC")

      # Glass 2
      find(".glasscutting2-type-select").select("LAM")
      find(".glasscutting2-thickness-select").select("3+3")
      find(".glasscutting2-color-select").select("INC")

      # Confirm DVH if necessary
      click_on "Confirmar"
    end

    # Create project
    click_on "Guardar como presupuesto"

    # Verifications - after redirect to projects_path
    assert_text "Proyecto creado exitosamente."
    assert_text "Proyecto SystemTest"  # Name of the project we created
    assert_current_path projects_path
  end
end
