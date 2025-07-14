require "test_helper"

class PrecioVidriosControllerTest < ActionDispatch::IntegrationTest
  setup do
    @precio_vidrio = precio_vidrios(:one)
  end

  test "should get index" do
    get precio_vidrios_url
    assert_response :success
  end

  test "should get new" do
    get new_precio_vidrio_url
    assert_response :success
  end

  test "should create precio_vidrio" do
    assert_difference("PrecioVidrio.count") do
      post precio_vidrios_url, params: { precio_vidrio: { alto: @precio_vidrio.alto, ancho: @precio_vidrio.ancho, color: @precio_vidrio.color, grosor: @precio_vidrio.grosor, precio: @precio_vidrio.precio, tipo: @precio_vidrio.tipo } }
    end

    assert_redirected_to precio_vidrio_url(PrecioVidrio.last)
  end

  test "should show precio_vidrio" do
    get precio_vidrio_url(@precio_vidrio)
    assert_response :success
  end

  test "should get edit" do
    get edit_precio_vidrio_url(@precio_vidrio)
    assert_response :success
  end

  test "should update precio_vidrio" do
    patch precio_vidrio_url(@precio_vidrio), params: { precio_vidrio: { alto: @precio_vidrio.alto, ancho: @precio_vidrio.ancho, color: @precio_vidrio.color, grosor: @precio_vidrio.grosor, precio: @precio_vidrio.precio, tipo: @precio_vidrio.tipo } }
    assert_redirected_to precio_vidrio_url(@precio_vidrio)
  end

  test "should destroy precio_vidrio" do
    assert_difference("PrecioVidrio.count", -1) do
      delete precio_vidrio_url(@precio_vidrio)
    end

    assert_redirected_to precio_vidrios_url
  end
end
