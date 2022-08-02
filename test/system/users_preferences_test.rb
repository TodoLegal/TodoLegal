require "application_system_test_case"

class UsersPreferencesTest < ApplicationSystemTestCase
  setup do
    @users_preference = users_preferences(:one)
  end

  test "visiting the index" do
    visit users_preferences_url
    assert_selector "h1", text: "Users Preferences"
  end

  test "creating a Users preference" do
    visit users_preferences_url
    click_on "New Users Preference"

    fill_in "Mail frequency", with: @users_preference.mail_frequency
    fill_in "Mail sent at", with: @users_preference.mail_sent_at
    fill_in "User", with: @users_preference.user_id
    fill_in "Users preferences tags", with: @users_preference.users_preferences_tags_id
    click_on "Create Users preference"

    assert_text "Users preference was successfully created"
    click_on "Back"
  end

  test "updating a Users preference" do
    visit users_preferences_url
    click_on "Edit", match: :first

    fill_in "Mail frequency", with: @users_preference.mail_frequency
    fill_in "Mail sent at", with: @users_preference.mail_sent_at
    fill_in "User", with: @users_preference.user_id
    fill_in "Users preferences tags", with: @users_preference.users_preferences_tags_id
    click_on "Update Users preference"

    assert_text "Users preference was successfully updated"
    click_on "Back"
  end

  test "destroying a Users preference" do
    visit users_preferences_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Users preference was successfully destroyed"
  end
end
