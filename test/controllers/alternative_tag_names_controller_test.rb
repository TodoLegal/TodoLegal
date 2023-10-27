require "test_helper"

class AlternativeTagNamesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @alternative_tag_name = alternative_tag_names(:one)
  end

  test "should get index" do
    get alternative_tag_names_url
    assert_response :success
  end

  test "should get new" do
    get new_alternative_tag_name_url
    assert_response :success
  end

  test "should create alternative_tag_name" do
    assert_difference('AlternativeTagName.count') do
      post alternative_tag_names_url, params: { alternative_tag_name: { alternative_name: @alternative_tag_name.alternative_name, tag_id: @alternative_tag_name.tag_id } }
    end

    assert_redirected_to alternative_tag_name_url(AlternativeTagName.last)
  end

  test "should show alternative_tag_name" do
    get alternative_tag_name_url(@alternative_tag_name)
    assert_response :success
  end

  test "should get edit" do
    get edit_alternative_tag_name_url(@alternative_tag_name)
    assert_response :success
  end

  test "should update alternative_tag_name" do
    patch alternative_tag_name_url(@alternative_tag_name), params: { alternative_tag_name: { alternative_name: @alternative_tag_name.alternative_name, tag_id: @alternative_tag_name.tag_id } }
    assert_redirected_to alternative_tag_name_url(@alternative_tag_name)
  end

  test "should destroy alternative_tag_name" do
    assert_difference('AlternativeTagName.count', -1) do
      delete alternative_tag_name_url(@alternative_tag_name)
    end

    assert_redirected_to alternative_tag_names_url
  end
end
