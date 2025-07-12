require "test_helper"

class GlassplatesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @glassplate = glassplates(:complete_sheet)
  end

  test "should get index" do
    get glassplates_url
    assert_response :success
    assert_select "h1", "Gestión de Stock"
  end

  test "should get new" do
    get new_glassplate_url
    assert_response :success
    assert_select "h1", "Agregar Nuevo Material"
  end

  test "should create glassplate" do
    assert_difference("Glassplate.count") do
      post glassplates_url, params: {
        glassplate: {
          width: 600,
          height: 400,
          color: "transparente",
          glass_type: "Incoloro",
          thickness: "4mm",
          standard_measures: "600x400mm",
          quantity: 5,
          location: "Estante A",
          status: "disponible",
          is_scrap: false
        }
      }
    end

    assert_redirected_to glassplates_url
    assert_equal "Material agregado exitosamente al stock.", flash[:notice]
  end

  test "should not create glassplate with invalid params" do
    assert_no_difference("Glassplate.count") do
      post glassplates_url, params: {
        glassplate: {
          width: nil,
          height: nil,
          color: "invalid_color",
          glass_type: "Invalid Type"
        }
      }
    end

    assert_response :unprocessable_entity
  end

  test "should show glassplate" do
    get glassplate_url(@glassplate)
    assert_response :success
  end

  test "should get edit" do
    get edit_glassplate_url(@glassplate)
    assert_response :success
    assert_select "h1", "Editar Material"
  end

  test "should update glassplate" do
    patch glassplate_url(@glassplate), params: {
      glassplate: {
        quantity: 10,
        location: "Estante B",
        status: "reservado"
      }
    }

    assert_redirected_to glassplates_url
    assert_equal "Material actualizado exitosamente.", flash[:notice]

    @glassplate.reload
    assert_equal 10, @glassplate.quantity
    assert_equal "Estante B", @glassplate.location
    assert_equal "reservado", @glassplate.status
  end

  test "should not update glassplate with invalid params" do
    patch glassplate_url(@glassplate), params: {
      glassplate: {
        width: -1,
        color: "invalid_color"
      }
    }

    assert_response :unprocessable_entity
  end

  test "should destroy glassplate" do
    assert_difference("Glassplate.count", -1) do
      delete glassplate_url(@glassplate)
    end

    assert_redirected_to glassplates_url
    assert_equal "Material eliminado exitosamente.", flash[:notice]
  end

  test "should load stock data correctly" do
    get glassplates_url
    assert_response :success

    # Check that stock summary data is available
    assert_not_nil assigns(:complete_sheets)
    assert_not_nil assigns(:scraps)
    assert_not_nil assigns(:stock_summary)
  end

  test "should calculate stock summary correctly" do
    get glassplates_url
    assert_response :success

    stock_summary = assigns(:stock_summary)
    assert_kind_of Hash, stock_summary
    assert_includes stock_summary.keys, :total_sheets
    assert_includes stock_summary.keys, :total_scraps
    assert_includes stock_summary.keys, :available_scraps
    assert_includes stock_summary.keys, :reserved_scraps
  end
end
