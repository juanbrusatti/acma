# test/controllers/glasscuttings_controller_test.rb
require 'test_helper'

class GlasscuttingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @project = projects(:one)
    @glasscutting_params = {
      glass_type: "LAM",      # inclusión válida: ["LAM","FLO","COL"]
      thickness: "5mm",       # inclusión válida: ["3+3","4+4","5+5","5mm"]
      height: 100,
      width: 80,
      color: "BLS",           # inclusión válida: ["INC","STB","GRS","BRC","BLS","STG","NTR"]
      typology: "Fijo",
      price: 150.0,
      type_opening: "PVC"      # inclusión válida: ["PVC","Aluminio"]
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
