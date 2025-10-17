# test/controllers/dvhs_controller_test.rb
require 'test_helper'

class DvhsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @project = projects(:one)
    dvh = dvhs(:one)
    @dvh_params = {
      innertube: dvh.innertube,
      typology: dvh.typology,
      height: dvh.height,
      width: dvh.width,
      type_opening: dvh.type_opening,
      glasscutting1_type: dvh.glasscutting1_type,
      glasscutting1_thickness: dvh.glasscutting1_thickness,
      glasscutting1_color: dvh.glasscutting1_color,
      glasscutting2_type: dvh.glasscutting2_type,
      glasscutting2_thickness: dvh.glasscutting2_thickness,
      glasscutting2_color: dvh.glasscutting2_color,
      price: dvh.price
    }
  end

  test "should create dvh" do
    assert_difference('Dvh.count') do
      post project_dvhs_url(@project), params: { dvh: @dvh_params }
    end
    assert_redirected_to edit_project_path(@project)
  end

  test "should not create dvh with invalid params" do
    assert_no_difference('Dvh.count') do
      post project_dvhs_url(@project), params: { dvh: { typology: "" } }
    end
    assert_redirected_to edit_project_path(@project)
  end
end
