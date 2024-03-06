require "test_helper"

class SummatoriesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @summatory = summatories(:one)
  end

  test "should get index" do
    get summatories_url
    assert_response :success
  end

  test "should get new" do
    get new_summatory_url
    assert_response :success
  end

  test "should create summatory" do
    assert_difference("Summatory.count") do
      post summatories_url, params: { summatory: { count_sum: @summatory.count_sum } }
    end

    assert_redirected_to summatory_url(Summatory.last)
  end

  test "should show summatory" do
    get summatory_url(@summatory)
    assert_response :success
  end

  test "should get edit" do
    get edit_summatory_url(@summatory)
    assert_response :success
  end

  test "should update summatory" do
    patch summatory_url(@summatory), params: { summatory: { count_sum: @summatory.count_sum } }
    assert_redirected_to summatory_url(@summatory)
  end

  test "should destroy summatory" do
    assert_difference("Summatory.count", -1) do
      delete summatory_url(@summatory)
    end

    assert_redirected_to summatories_url
  end
end
