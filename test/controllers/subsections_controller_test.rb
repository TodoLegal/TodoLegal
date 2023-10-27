require 'test_helper'

class SubsectionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @subsection = subsections(:one)
  end

  test "should get index" do
    get subsections_url
    assert_response :success
  end

  test "should get new" do
    get new_subsection_url
    assert_response :success
  end

  test "should create subsection" do
    assert_difference('Subsection.count') do
      post subsections_url, params: { subsection: { name: @subsection.name, number: @subsection.number, position: @subsection.position } }
    end

    assert_redirected_to subsection_url(Subsection.last)
  end

  test "should show subsection" do
    get subsection_url(@subsection)
    assert_response :success
  end

  test "should get edit" do
    get edit_subsection_url(@subsection)
    assert_response :success
  end

  test "should update subsection" do
    patch subsection_url(@subsection), params: { subsection: { name: @subsection.name, number: @subsection.number, position: @subsection.position } }
    assert_redirected_to subsection_url(@subsection)
  end

  test "should destroy subsection" do
    assert_difference('Subsection.count', -1) do
      delete subsection_url(@subsection)
    end

    assert_redirected_to subsections_url
  end
end
