require "test_helper"

class UsersPreferencesTagsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @users_preferences_tag = users_preferences_tags(:one)
  end

  test "should get index" do
    get users_preferences_tags_url
    assert_response :success
  end

  test "should get new" do
    get new_users_preferences_tag_url
    assert_response :success
  end

  test "should create users_preferences_tag" do
    assert_difference('UsersPreferencesTag.count') do
      post users_preferences_tags_url, params: { users_preferences_tag: { tag_id: @users_preferences_tag.tag_id } }
    end

    assert_redirected_to users_preferences_tag_url(UsersPreferencesTag.last)
  end

  test "should show users_preferences_tag" do
    get users_preferences_tag_url(@users_preferences_tag)
    assert_response :success
  end

  test "should get edit" do
    get edit_users_preferences_tag_url(@users_preferences_tag)
    assert_response :success
  end

  test "should update users_preferences_tag" do
    patch users_preferences_tag_url(@users_preferences_tag), params: { users_preferences_tag: { tag_id: @users_preferences_tag.tag_id } }
    assert_redirected_to users_preferences_tag_url(@users_preferences_tag)
  end

  test "should destroy users_preferences_tag" do
    assert_difference('UsersPreferencesTag.count', -1) do
      delete users_preferences_tag_url(@users_preferences_tag)
    end

    assert_redirected_to users_preferences_tags_url
  end
end
