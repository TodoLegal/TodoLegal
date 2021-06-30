require "application_system_test_case"

class TagTypesTest < ApplicationSystemTestCase
  setup do
    @tag_type = tag_types(:one)
  end

  test "visiting the index" do
    visit tag_types_url
    assert_selector "h1", text: "Tag Types"
  end

  test "creating a Tag type" do
    visit tag_types_url
    click_on "New Tag Type"

    fill_in "Name", with: @tag_type.name
    click_on "Create Tag type"

    assert_text "Tag type was successfully created"
    click_on "Back"
  end

  test "updating a Tag type" do
    visit tag_types_url
    click_on "Edit", match: :first

    fill_in "Name", with: @tag_type.name
    click_on "Update Tag type"

    assert_text "Tag type was successfully updated"
    click_on "Back"
  end

  test "destroying a Tag type" do
    visit tag_types_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Tag type was successfully destroyed"
  end
end
