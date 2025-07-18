require "application_system_test_case"

class InsumosTest < ApplicationSystemTestCase
  setup do
    @insumo = insumos(:one)
  end

  test "visiting the index" do
    visit insumos_url
    assert_selector "h1", text: "Insumos"
  end

  test "should create insumo" do
    visit insumos_url
    click_on "New insumo"

    fill_in "Nombre", with: @insumo.nombre
    fill_in "Precio", with: @insumo.precio
    click_on "Create Insumo"

    assert_text "Insumo was successfully created"
    click_on "Back"
  end

  test "should update Insumo" do
    visit insumo_url(@insumo)
    click_on "Edit this insumo", match: :first

    fill_in "Nombre", with: @insumo.nombre
    fill_in "Precio", with: @insumo.precio
    click_on "Update Insumo"

    assert_text "Insumo was successfully updated"
    click_on "Back"
  end

  test "should destroy Insumo" do
    visit insumo_url(@insumo)
    click_on "Destroy this insumo", match: :first

    assert_text "Insumo was successfully destroyed"
  end
end
