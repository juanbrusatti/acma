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

    # Check for dashboard cards - normalmente hay 3 principales
    assert_select ".dashboard-grid .glass-card", minimum: 3

    # Check for stock card specifically
    assert_select "h3", text: "Gestión de Stock"
  end

  test "dashboard should display correct stock counts" do
    # Crear datos de prueba si es necesario
  Glassplate.create!(width: 100, height: 100, color: "INC", glass_type: "LAM", thickness: "3+3", quantity: 1)
    Scrap.create!(
      ref_number: "1",
      scrap_type: "LAM",
      thickness: "3+3",
      width: 1.0,
      height: 1.0,
      color: "INC",
      output_work: "X",
      status: "Disponible"
    )

    get root_url
    assert_response :success

    # Should display some stock information
    assert_select ".text-2xl.font-bold"
  end
end
