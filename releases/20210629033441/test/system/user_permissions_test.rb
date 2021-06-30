require "application_system_test_case"

class UserPermissionsTest < ApplicationSystemTestCase
  setup do
    @user_permission = user_permissions(:one)
  end

  test "visiting the index" do
    visit user_permissions_url
    assert_selector "h1", text: "User Permissions"
  end

  test "creating a User permission" do
    visit user_permissions_url
    click_on "New User Permission"

    fill_in "Permission", with: @user_permission.permission_id
    fill_in "User", with: @user_permission.user_id
    click_on "Create User permission"

    assert_text "User permission was successfully created"
    click_on "Back"
  end

  test "updating a User permission" do
    visit user_permissions_url
    click_on "Edit", match: :first

    fill_in "Permission", with: @user_permission.permission_id
    fill_in "User", with: @user_permission.user_id
    click_on "Update User permission"

    assert_text "User permission was successfully updated"
    click_on "Back"
  end

  test "destroying a User permission" do
    visit user_permissions_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "User permission was successfully destroyed"
  end
end
