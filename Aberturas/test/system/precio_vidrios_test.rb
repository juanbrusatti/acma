require "application_system_test_case"

class PrecioVidriosTest < ApplicationSystemTestCase
  setup do
    @precio_vidrio = precio_vidrios(:one)
  end

  test "visiting the index" do
    visit precio_vidrios_url
    assert_selector "h1", text: "Precio vidrios"
  end

  test "should create precio vidrio" do
    visit precio_vidrios_url
    click_on "New precio vidrio"

    fill_in "Alto", with: @precio_vidrio.alto
    fill_in "Ancho", with: @precio_vidrio.ancho
    fill_in "Color", with: @precio_vidrio.color
    fill_in "Grosor", with: @precio_vidrio.grosor
    fill_in "Precio", with: @precio_vidrio.precio
    fill_in "Tipo", with: @precio_vidrio.tipo
    click_on "Create Precio vidrio"

    assert_text "Precio vidrio was successfully created"
    click_on "Back"
  end

  test "should update Precio vidrio" do
    visit precio_vidrio_url(@precio_vidrio)
    click_on "Edit this precio vidrio", match: :first

    fill_in "Alto", with: @precio_vidrio.alto
    fill_in "Ancho", with: @precio_vidrio.ancho
    fill_in "Color", with: @precio_vidrio.color
    fill_in "Grosor", with: @precio_vidrio.grosor
    fill_in "Precio", with: @precio_vidrio.precio
    fill_in "Tipo", with: @precio_vidrio.tipo
    click_on "Update Precio vidrio"

    assert_text "Precio vidrio was successfully updated"
    click_on "Back"
  end

  test "should destroy Precio vidrio" do
    visit precio_vidrio_url(@precio_vidrio)
    click_on "Destroy this precio vidrio", match: :first

    assert_text "Precio vidrio was successfully destroyed"
  end
end
