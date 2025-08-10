require "application_system_test_case"

class SuppliesTest < ApplicationSystemTestCase
  setup do
    @supply = supplies(:one)
  end

  test "should get index" do
    visit supplies_url
    assert_selector "h1", text: "Insumos"
  end

  test "should create supply" do
    visit supplies_url
    click_on "Nuevo insumo"

    fill_in "Nombre", with: @supply.name
    fill_in "Precio", with: @supply.price
    click_on "Crear Insumo"

    assert_text "Insumo was successfully created"
    click_on "Volver"
  end

  test "should update Supply" do
    visit supply_url(@supply)
    click_on "Editar este insumo", match: :first

    fill_in "Nombre", with: @supply.name
    fill_in "Precio", with: @supply.price
    click_on "Actualizar Insumo"

    assert_text "Insumo was successfully updated"
    click_on "Volver"
  end

  test "should destroy Supply" do
    visit supply_url(@supply)
    click_on "Eliminar este insumo", match: :first

    assert_text "Insumo was successfully destroyed"
  end
end
