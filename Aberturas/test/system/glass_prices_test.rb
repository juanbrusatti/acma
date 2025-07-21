require "application_system_test_case"

class GlassPricesTest < ApplicationSystemTestCase
  setup do
    @glass_price = glass_prices(:one)
  end

  test "should get index" do
    visit glass_prices_url
    assert_selector "h1", text: "Precios de Vidrios"
  end

  test "should create glass_price" do
    visit glass_prices_url
    click_on "Nuevo precio vidrio"

    fill_in "Tipo", with: @glass_price.type
    fill_in "Grosor", with: @glass_price.thickness
    fill_in "Color", with: @glass_price.color
    fill_in "Precio", with: @glass_price.price
    fill_in "Precio por m²", with: @glass_price.price_m2
    click_on "Crear Precio vidrio"

    assert_text "Precio vidrio was successfully created"
    click_on "Volver"
  end

  test "should update GlassPrice" do
    visit glass_price_url(@glass_price)
    click_on "Editar este precio vidrio", match: :first

    fill_in "Tipo", with: @glass_price.type
    fill_in "Grosor", with: @glass_price.thickness
    fill_in "Color", with: @glass_price.color
    fill_in "Precio", with: @glass_price.price
    fill_in "Precio por m²", with: @glass_price.price_m2
    click_on "Actualizar Precio vidrio"

    assert_text "Precio vidrio was successfully updated"
    click_on "Volver"
  end

  test "should destroy GlassPrice" do
    visit glass_price_url(@glass_price)
    click_on "Eliminar este precio vidrio", match: :first

    assert_text "Precio vidrio was successfully destroyed"
  end
end
