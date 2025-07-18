require "test_helper"

class DvhsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @project = projects(:one)  # Asegurate de tener este fixture
  end

  test "should create dvh with valid params" do
    assert_difference("Dvh.count") do
      post project_dvhs_url(@project), params: {
        dvh: {
          height: 120,
          width: 100,
          location: "Taller A",
          innertube: "Camera 1",
          glasscutting1_type: "Incoloro",
          glasscutting1_thickness: "4mm",
          glasscutting1_color: "Transparente",
          glasscutting2_type: "Incoloro",
          glasscutting2_thickness: "4mm",
          glasscutting2_color: "Transparente"
          # gas_type: "Argón"
        }
      }
    end

    assert_redirected_to edit_project_path(@project)
    assert_equal "DVH agregado correctamente.", flash[:notice]
  end

  test "should not create dvh with invalid params" do
    assert_no_difference("Dvh.count") do
      post project_dvhs_url(@project), params: {
        dvh: {
          height: nil, width: nil
        }
      }
    end

    assert_redirected_to edit_project_path(@project)
    assert_equal "Error al agregar DVH.", flash[:alert]
  end
end
