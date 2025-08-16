require "application_system_test_case"

class ScrapsTest < ApplicationSystemTestCase
  setup do
    @scrap = scraps(:one)
  end

  test "visiting the index" do
    visit scraps_url
    assert_selector "h1", text: "Scraps"
  end

  test "should create scrap" do
    visit scraps_url
    click_on "New scrap"

    fill_in "Height", with: @scrap.height
    fill_in "Output work", with: @scrap.output_work
    fill_in "Ref number", with: @scrap.ref_number
    fill_in "Scrap type", with: @scrap.scrap_type
    fill_in "Status", with: @scrap.status
    fill_in "Thickness", with: @scrap.thickness
    fill_in "Width", with: @scrap.width
    click_on "Create Scrap"

    assert_text "Scrap was successfully created"
    click_on "Back"
  end

  test "should update Scrap" do
    visit scrap_url(@scrap)
    click_on "Edit this scrap", match: :first

    fill_in "Height", with: @scrap.height
    fill_in "Output work", with: @scrap.output_work
    fill_in "Ref number", with: @scrap.ref_number
    fill_in "Scrap type", with: @scrap.scrap_type
    fill_in "Status", with: @scrap.status
    fill_in "Thickness", with: @scrap.thickness
    fill_in "Width", with: @scrap.width
    click_on "Update Scrap"

    assert_text "Scrap was successfully updated"
    click_on "Back"
  end

  test "should destroy Scrap" do
    visit scrap_url(@scrap)
    click_on "Destroy this scrap", match: :first

    assert_text "Scrap was successfully destroyed"
  end
end
