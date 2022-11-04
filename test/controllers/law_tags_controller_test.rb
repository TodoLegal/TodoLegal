require 'test_helper'

class LawTagsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @law_tag = law_tags(:one)
  end

  test "should get index" do
    get law_tags_url
    assert_response :success
  end

  test "should get new" do
    get new_law_tag_url
    assert_response :success
  end

  test "should create law_tag" do
    assert_difference('LawTag.count') do
      post law_tags_url, params: { law_tag: { law_id: @law_tag.law_id, tag_id: @law_tag.tag_id } }
    end

    assert_redirected_to law_tag_url(LawTag.last)
  end

  test "should show law_tag" do
    get law_tag_url(@law_tag)
    assert_response :success
  end

  test "should get edit" do
    get edit_law_tag_url(@law_tag)
    assert_response :success
  end

  test "should update law_tag" do
    patch law_tag_url(@law_tag), params: { law_tag: { law_id: @law_tag.law_id, tag_id: @law_tag.tag_id } }
    assert_redirected_to law_tag_url(@law_tag)
  end

  test "should destroy law_tag" do
    assert_difference('LawTag.count', -1) do
      delete law_tag_url(@law_tag)
    end

    assert_redirected_to law_tags_url
  end
end
