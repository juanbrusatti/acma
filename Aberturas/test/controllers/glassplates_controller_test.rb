require "test_helper"

class GlassplatesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @glassplate = glassplates(:one)
  end

  test "should get index" do
    get glassplates_url
    assert_response :success
  end

  test "should get new" do
    get new_glassplate_url
    assert_response :success
  end

  test "should create glassplate" do
    assert_difference("Glassplate.count") do
      post glassplates_url, params: { glassplate: { color: @glassplate.color, height: @glassplate.height, type: @glassplate.type, width: @glassplate.width } }
    end

    assert_redirected_to glassplate_url(Glassplate.last)
  end

  test "should show glassplate" do
    get glassplate_url(@glassplate)
    assert_response :success
  end

  test "should get edit" do
    get edit_glassplate_url(@glassplate)
    assert_response :success
  end

  test "should update glassplate" do
    patch glassplate_url(@glassplate), params: { glassplate: { color: @glassplate.color, height: @glassplate.height, type: @glassplate.type, width: @glassplate.width } }
    assert_redirected_to glassplate_url(@glassplate)
  end

  test "should destroy glassplate" do
    assert_difference("Glassplate.count", -1) do
      delete glassplate_url(@glassplate)
    end

    assert_redirected_to glassplates_url
  end
end
