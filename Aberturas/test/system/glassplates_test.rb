require "application_system_test_case"

class GlassplatesTest < ApplicationSystemTestCase
  setup do
    @glassplate = glassplates(:one)
  end

  test "visiting the index" do
    visit glassplates_url
    assert_selector "h1", text: "Glassplates"
  end

  test "should create glassplate" do
    visit glassplates_url
    click_on "New glassplate"

    fill_in "Color", with: @glassplate.color
    fill_in "Height", with: @glassplate.height
    fill_in "Type", with: @glassplate.type
    fill_in "Width", with: @glassplate.width
    click_on "Create Glassplate"

    assert_text "Glassplate was successfully created"
    click_on "Back"
  end

  test "should update Glassplate" do
    visit glassplate_url(@glassplate)
    click_on "Edit this glassplate", match: :first

    fill_in "Color", with: @glassplate.color
    fill_in "Height", with: @glassplate.height
    fill_in "Type", with: @glassplate.type
    fill_in "Width", with: @glassplate.width
    click_on "Update Glassplate"

    assert_text "Glassplate was successfully updated"
    click_on "Back"
  end

  test "should destroy Glassplate" do
    visit glassplate_url(@glassplate)
    accept_confirm { click_on "Destroy this glassplate", match: :first }

    assert_text "Glassplate was successfully destroyed"
  end
end
