require 'test_helper'

class LawModificationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @law_modification = law_modifications(:one)
  end

  test "should get index" do
    get law_modifications_url
    assert_response :success
  end

  test "should get new" do
    get new_law_modification_url
    assert_response :success
  end

  test "should create law_modification" do
    assert_difference('LawModification.count') do
      post law_modifications_url, params: { law_modification: { law_id: @law_modification.law_id, name: @law_modification.name } }
    end

    assert_redirected_to law_modification_url(LawModification.last)
  end

  test "should show law_modification" do
    get law_modification_url(@law_modification)
    assert_response :success
  end

  test "should get edit" do
    get edit_law_modification_url(@law_modification)
    assert_response :success
  end

  test "should update law_modification" do
    patch law_modification_url(@law_modification), params: { law_modification: { law_id: @law_modification.law_id, name: @law_modification.name } }
    assert_redirected_to law_modification_url(@law_modification)
  end

  test "should destroy law_modification" do
    assert_difference('LawModification.count', -1) do
      delete law_modification_url(@law_modification)
    end

    assert_redirected_to law_modifications_url
  end
end
