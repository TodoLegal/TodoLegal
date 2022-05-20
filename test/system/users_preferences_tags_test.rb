require "application_system_test_case"

class UsersPreferencesTagsTest < ApplicationSystemTestCase
  setup do
    @users_preferences_tag = users_preferences_tags(:one)
  end

  test "visiting the index" do
    visit users_preferences_tags_url
    assert_selector "h1", text: "Users Preferences Tags"
  end

  test "creating a Users preferences tag" do
    visit users_preferences_tags_url
    click_on "New Users Preferences Tag"

    fill_in "Tag", with: @users_preferences_tag.tag_id
    click_on "Create Users preferences tag"

    assert_text "Users preferences tag was successfully created"
    click_on "Back"
  end

  test "updating a Users preferences tag" do
    visit users_preferences_tags_url
    click_on "Edit", match: :first

    fill_in "Tag", with: @users_preferences_tag.tag_id
    click_on "Update Users preferences tag"

    assert_text "Users preferences tag was successfully updated"
    click_on "Back"
  end

  test "destroying a Users preferences tag" do
    visit users_preferences_tags_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Users preferences tag was successfully destroyed"
  end
end
