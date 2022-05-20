require "test_helper"

class UsersPreferencesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @users_preference = users_preferences(:one)
  end

  test "should get index" do
    get users_preferences_url
    assert_response :success
  end

  test "should get new" do
    get new_users_preference_url
    assert_response :success
  end

  test "should create users_preference" do
    assert_difference('UsersPreference.count') do
      post users_preferences_url, params: { users_preference: { mail_frequency: @users_preference.mail_frequency, mail_sent_at: @users_preference.mail_sent_at, user_id: @users_preference.user_id, users_preferences_tags_id: @users_preference.users_preferences_tags_id } }
    end

    assert_redirected_to users_preference_url(UsersPreference.last)
  end

  test "should show users_preference" do
    get users_preference_url(@users_preference)
    assert_response :success
  end

  test "should get edit" do
    get edit_users_preference_url(@users_preference)
    assert_response :success
  end

  test "should update users_preference" do
    patch users_preference_url(@users_preference), params: { users_preference: { mail_frequency: @users_preference.mail_frequency, mail_sent_at: @users_preference.mail_sent_at, user_id: @users_preference.user_id, users_preferences_tags_id: @users_preference.users_preferences_tags_id } }
    assert_redirected_to users_preference_url(@users_preference)
  end

  test "should destroy users_preference" do
    assert_difference('UsersPreference.count', -1) do
      delete users_preference_url(@users_preference)
    end

    assert_redirected_to users_preferences_url
  end
end
