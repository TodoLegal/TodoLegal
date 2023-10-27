require "test_helper"

class DatapointsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @datapoint = datapoints(:one)
  end

  test "should get index" do
    get datapoints_url
    assert_response :success
  end

  test "should get new" do
    get new_datapoint_url
    assert_response :success
  end

  test "should create datapoint" do
    assert_difference('Datapoint.count') do
      post datapoints_url, params: { datapoint: { name: @datapoint.name, priority: @datapoint.priority, user_permission_id: @datapoint.user_permission_id } }
    end

    assert_redirected_to datapoint_url(Datapoint.last)
  end

  test "should show datapoint" do
    get datapoint_url(@datapoint)
    assert_response :success
  end

  test "should get edit" do
    get edit_datapoint_url(@datapoint)
    assert_response :success
  end

  test "should update datapoint" do
    patch datapoint_url(@datapoint), params: { datapoint: { name: @datapoint.name, priority: @datapoint.priority, user_permission_id: @datapoint.user_permission_id } }
    assert_redirected_to datapoint_url(@datapoint)
  end

  test "should destroy datapoint" do
    assert_difference('Datapoint.count', -1) do
      delete datapoint_url(@datapoint)
    end

    assert_redirected_to datapoints_url
  end
end
