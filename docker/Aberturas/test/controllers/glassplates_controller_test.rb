require "test_helper"

class GlassplatesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @glassplate = glassplates(:one)
  end

  test "should get index" do
    get glassplates_url
    assert_response :success
    assert_select "h1", "Gestión de Stock"
  end

  test "should get new" do
    get new_glassplate_url
    assert_response :success
    assert_select "h1", "'Agregar plancha'"
  end

  test "should create glassplate" do
    assert_difference("Glassplate.count") do
      post glassplates_url, params: {
        glassplate: {
          width: 600,
          height: 400,
          color: "INC",
          glass_type: "LAM",
          thickness: "4+4",
          quantity: 1
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
          glass_type: "Invalid Type",
          thickness: "invalid",
          quantity: nil
        }
      }
    end
    assert_response :unprocessable_entity
  end

  test "should get edit" do
    get edit_glassplate_url(@glassplate)
    assert_response :success
    assert_select "h1", "Editar plancha"
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

end
