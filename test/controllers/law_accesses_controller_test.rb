require 'test_helper'

class LawAccessesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @law_access = law_accesses(:one)
  end

  test "should get index" do
    get law_accesses_url
    assert_response :success
  end

  test "should get new" do
    get new_law_access_url
    assert_response :success
  end

  test "should create law_access" do
    assert_difference('LawAccess.count') do
      post law_accesses_url, params: { law_access: { name: @law_access.name } }
    end

    assert_redirected_to law_access_url(LawAccess.last)
  end

  test "should show law_access" do
    get law_access_url(@law_access)
    assert_response :success
  end

  test "should get edit" do
    get edit_law_access_url(@law_access)
    assert_response :success
  end

  test "should update law_access" do
    patch law_access_url(@law_access), params: { law_access: { name: @law_access.name } }
    assert_redirected_to law_access_url(@law_access)
  end

  test "should destroy law_access" do
    assert_difference('LawAccess.count', -1) do
      delete law_access_url(@law_access)
    end

    assert_redirected_to law_accesses_url
  end
end
