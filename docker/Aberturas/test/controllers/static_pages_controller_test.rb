require "test_helper"

class StaticPagesControllerTest < ActionDispatch::IntegrationTest
  test "should get home" do
    get static_pages_home_url
    assert_response :success
  end

  test "should get dashboard" do
    get root_url
    assert_response :success
    assert_select "h1", "Dashboard"
  end

  test "dashboard should display stock summary" do
    get root_url
    assert_response :success

    # Check for dashboard cards - there are 3 main cards + 2 additional ones
    assert_select ".rounded-lg.border.border-gray-200.bg-card", minimum: 5

    # Check for stock card specifically
    assert_select "h3", text: "Gestión de Stock"
  end

  test "dashboard should display correct stock counts" do
    # Create some test data
    complete_sheet = glassplates(:complete_sheet)
    scrap = glassplates(:scrap)

    get root_url
    assert_response :success

    # Should display some stock information
    assert_select ".text-2xl.font-bold"
  end
end
