require 'test_helper'

class UserPermissionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user_permission = user_permissions(:one)
  end

  test "should get index" do
    get user_permissions_url
    assert_response :success
  end

  test "should get new" do
    get new_user_permission_url
    assert_response :success
  end

  test "should create user_permission" do
    assert_difference('UserPermission.count') do
      post user_permissions_url, params: { user_permission: { permission_id: @user_permission.permission_id, user_id: @user_permission.user_id } }
    end

    assert_redirected_to user_permission_url(UserPermission.last)
  end

  test "should show user_permission" do
    get user_permission_url(@user_permission)
    assert_response :success
  end

  test "should get edit" do
    get edit_user_permission_url(@user_permission)
    assert_response :success
  end

  test "should update user_permission" do
    patch user_permission_url(@user_permission), params: { user_permission: { permission_id: @user_permission.permission_id, user_id: @user_permission.user_id } }
    assert_redirected_to user_permission_url(@user_permission)
  end

  test "should destroy user_permission" do
    assert_difference('UserPermission.count', -1) do
      delete user_permission_url(@user_permission)
    end

    assert_redirected_to user_permissions_url
  end
end
