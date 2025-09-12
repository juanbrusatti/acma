require "test_helper"

class OfficialRatesControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get official_rates_index_url
    assert_response :success
  end

  test "should get show" do
    get official_rates_show_url
    assert_response :success
  end

  test "should get update_manual" do
    get official_rates_update_manual_url
    assert_response :success
  end

  test "should get api_status" do
    get official_rates_api_status_url
    assert_response :success
  end
end
