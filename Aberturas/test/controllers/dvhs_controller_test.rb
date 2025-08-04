require "test_helper"

class DvhsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @project = projects(:one) 
  end

  test "should create dvh with valid params" do
    assert_difference("Dvh.count") do
      post project_dvhs_url(@project), params: {
        dvh: {
          height: 120,
          width: 100,
          typology: "V001",
          innertube: "9",
          glasscutting1_type: "LAM",
          glasscutting1_thickness: "3+3",
          glasscutting1_color: "INC",
          glasscutting2_type: "LAM",
          glasscutting2_thickness: "3+3",
          glasscutting2_color: "INC"
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
