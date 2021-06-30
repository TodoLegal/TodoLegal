require 'test_helper'

class TagTypesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @tag_type = tag_types(:one)
  end

  test "should get index" do
    get tag_types_url
    assert_response :success
  end

  test "should get new" do
    get new_tag_type_url
    assert_response :success
  end

  test "should create tag_type" do
    assert_difference('TagType.count') do
      post tag_types_url, params: { tag_type: { name: @tag_type.name } }
    end

    assert_redirected_to tag_type_url(TagType.last)
  end

  test "should show tag_type" do
    get tag_type_url(@tag_type)
    assert_response :success
  end

  test "should get edit" do
    get edit_tag_type_url(@tag_type)
    assert_response :success
  end

  test "should update tag_type" do
    patch tag_type_url(@tag_type), params: { tag_type: { name: @tag_type.name } }
    assert_redirected_to tag_type_url(@tag_type)
  end

  test "should destroy tag_type" do
    assert_difference('TagType.count', -1) do
      delete tag_type_url(@tag_type)
    end

    assert_redirected_to tag_types_url
  end
end
