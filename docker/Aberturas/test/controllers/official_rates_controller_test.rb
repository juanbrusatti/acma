# test/controllers/official_rates_controller_test.rb
require 'test_helper'

class OfficialRatesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @official_rate = official_rate_histories(:one)
  end

  test "should get index" do
    get official_rates_url
    assert_response :success
  end

  test "should show official_rate" do
    get official_rate_url(@official_rate)
    assert_response :success
  end
end
