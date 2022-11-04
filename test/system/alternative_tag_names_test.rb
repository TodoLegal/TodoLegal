require "application_system_test_case"

class AlternativeTagNamesTest < ApplicationSystemTestCase
  setup do
    @alternative_tag_name = alternative_tag_names(:one)
  end

  test "visiting the index" do
    visit alternative_tag_names_url
    assert_selector "h1", text: "Alternative Tag Names"
  end

  test "creating a Alternative tag name" do
    visit alternative_tag_names_url
    click_on "New Alternative Tag Name"

    fill_in "Alternative name", with: @alternative_tag_name.alternative_name
    fill_in "Tag", with: @alternative_tag_name.tag_id
    click_on "Create Alternative tag name"

    assert_text "Alternative tag name was successfully created"
    click_on "Back"
  end

  test "updating a Alternative tag name" do
    visit alternative_tag_names_url
    click_on "Edit", match: :first

    fill_in "Alternative name", with: @alternative_tag_name.alternative_name
    fill_in "Tag", with: @alternative_tag_name.tag_id
    click_on "Update Alternative tag name"

    assert_text "Alternative tag name was successfully updated"
    click_on "Back"
  end

  test "destroying a Alternative tag name" do
    visit alternative_tag_names_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Alternative tag name was successfully destroyed"
  end
end
