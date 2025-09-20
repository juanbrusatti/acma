require "test_helper"

class OfficialRatesControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get official_rates_url
    assert_response :success
  end

  test "should get show" do
    get official_rate_url(1)
    assert_response :success
  end

  test "should get update_manual" do
    get update_manual_official_rates_url
    assert_response :success
  end

  test "should get api_status" do
    get api_status_official_rates_url
    assert_response :success
  end
end
