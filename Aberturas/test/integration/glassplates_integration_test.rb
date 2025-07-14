require "test_helper"

class GlassplatesIntegrationTest < ActionDispatch::IntegrationTest
  setup do
    @glassplate = glassplates(:complete_sheet)
  end

  test "complete glassplate workflow" do
    # 1. Visit index
    get glassplates_url
    assert_response :success
    assert_select "h1", "Gestión de Stock"

    # 2. Create new glassplate
    get new_glassplate_url
    assert_response :success

    post glassplates_url, params: {
      glassplate: {
        width: 800,
        height: 600,
        color: "transparente",
        glass_type: "Incoloro",
        thickness: "6mm",
        standard_measures: "800x600mm",
        quantity: 3,
        location: "Estante C",
        status: "disponible",
        is_scrap: false
      }
    }

    assert_redirected_to glassplates_url
    assert_equal "Material agregado exitosamente al stock.", flash[:notice]

    # 3. Verify it appears in the list
    get glassplates_url
    assert_response :success
    assert_select "td", "Incoloro"
    assert_select "td", "6mm"

    # 4. Edit the glassplate
    new_glassplate = Glassplate.last
    get edit_glassplate_url(new_glassplate)
    assert_response :success

    patch glassplate_url(new_glassplate), params: {
      glassplate: {
        quantity: 5,
        status: "reservado"
      }
    }

    assert_redirected_to glassplates_url
    assert_equal "Material actualizado exitosamente.", flash[:notice]

    # 5. Verify the update
    new_glassplate.reload
    assert_equal 5, new_glassplate.quantity
    assert_equal "reservado", new_glassplate.status

    # 6. Delete the glassplate
    assert_difference("Glassplate.count", -1) do
      delete glassplate_url(new_glassplate)
    end

    assert_redirected_to glassplates_url
    assert_equal "Material eliminado exitosamente.", flash[:notice]
  end

  test "scrap workflow" do
    # Create a scrap
    post glassplates_url, params: {
      glassplate: {
        width: 300,
        height: 200,
        color: "azul",
        glass_type: "Templado",
        thickness: "4mm",
        standard_measures: "300x200mm",
        quantity: 1,
        location: "Rack de sobrantes",
        status: "disponible",
        is_scrap: true
      }
    }

    assert_redirected_to glassplates_url

    # Verify it's created as scrap
    scrap = Glassplate.last
    assert scrap.is_scrap?
    assert_equal "disponible", scrap.status
  end

  test "stock summary calculation" do
    # We have fixtures: complete_sheet (qty: 10), scrap, available, reserved, one (qty: 5), two (qty: 3)
    get glassplates_url
    assert_response :success

    stock_summary = assigns(:stock_summary)

    # Should calculate correctly from fixtures
    # complete_sheet: 10, one: 5, two: 3 = 18 total sheets
    assert_equal 18, stock_summary[:total_sheets]
    assert_equal 3, stock_summary[:total_scraps]  # scrap, available, reserved fixtures
    assert_equal 2, stock_summary[:available_scraps] # scrap and available fixtures
    assert_equal 1, stock_summary[:reserved_scraps]  # reserved fixture
  end

  test "validation errors display correctly" do
    # Try to create invalid glassplate
    post glassplates_url, params: {
      glassplate: {
        width: -1,
        height: 0,
        color: "invalid_color",
        glass_type: "Invalid Type"
      }
    }

    assert_response :unprocessable_entity

    # Should render new form with errors
    assert_select "div", text: /error/i
  end

  test "navigation between pages" do
    # Test navigation from index to new and back
    get glassplates_url
    assert_response :success

    get new_glassplate_url
    assert_response :success

    get glassplates_url
    assert_response :success

    # Test navigation to edit and back
    get edit_glassplate_url(@glassplate)
    assert_response :success

    get glassplates_url
    assert_response :success
  end
end
