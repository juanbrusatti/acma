require "test_helper"

class GlasscuttingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @project = projects(:one)
  end

  test "should create glasscutting with valid params" do
    assert_difference("Glasscutting.count") do
      post project_glasscuttings_url(@project), params: {
        glasscutting: {
          glass_type: "Incoloro",
          thickness: "4mm",
          height: 120,
          width: 80,
          color: "Transparente",
          location: "Mesa 1"
        }
      }
    end

    assert_redirected_to edit_project_path(@project)
    assert_equal "Vidrio simple agregado correctamente.", flash[:notice]
  end

  test "should not create glasscutting with invalid params" do
    assert_no_difference("Glasscutting.count") do
      post project_glasscuttings_url(@project), params: {
        glasscutting: {
          height: nil,
          width: nil
        }
      }
    end

    assert_redirected_to edit_project_path(@project)
    assert_equal "Error al agregar vidrio simple.", flash[:alert]
  end
end
