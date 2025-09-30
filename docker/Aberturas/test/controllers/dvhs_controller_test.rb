# test/controllers/dvhs_controller_test.rb
require 'test_helper'

class DvhsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @project = projects(:one)
    @dvh_params = {
      innertube: 12,               # válido según modelo: [6,9,12,20]
      typology: "Corrediza",
      height: 200,
      width: 100,
      type_opening: "PVC",        # válido: ["PVC","Aluminio"]
      glasscutting1_type: "LAM",  # válido: ["LAM","FLO","COL"]
      glasscutting1_thickness: "5mm", # válido: ["3+3","4+4","5+5","5mm"]
      glasscutting1_color: "BLS",     # válido: ["INC","STB","GRS","BRC","BLS","STG","NTR"]
      glasscutting2_type: "FLO",
      glasscutting2_thickness: "4+4",
      glasscutting2_color: "INC",
      price: 300.0
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
