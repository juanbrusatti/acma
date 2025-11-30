# test/controllers/glasscuttings_controller_test.rb
require 'test_helper'

class GlasscuttingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @project = projects(:one)
    gc = glasscuttings(:one)
    @glasscutting_params = {
      glass_type: gc.glass_type,
      thickness: gc.thickness,
      height: gc.height,
      width: gc.width,
      color: gc.color,
      typology: gc.typology,
      price: gc.price,
      type_opening: gc.type_opening
    }
  end

  test "should create glasscutting" do
    assert_difference('Glasscutting.count', 1) do
      post project_glasscuttings_url(@project), params: { 
        glasscutting: @glasscutting_params 
      }
    end
    assert_redirected_to edit_project_path(@project)
  end

  test "should not create glasscutting with invalid params" do
    assert_no_difference('Glasscutting.count') do
      post project_glasscuttings_url(@project), params: { 
        glasscutting: { glass_type: "" } 
      }
    end
    assert_redirected_to edit_project_path(@project)
  end
end
