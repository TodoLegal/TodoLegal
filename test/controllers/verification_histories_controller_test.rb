require "test_helper"

class VerificationHistoriesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @verification_history = verification_histories(:one)
  end

  test "should get index" do
    get verification_histories_url
    assert_response :success
  end

  test "should get new" do
    get new_verification_history_url
    assert_response :success
  end

  test "should create verification_history" do
    assert_difference('VerificationHistory.count') do
      post verification_histories_url, params: { verification_history: { comments: @verification_history.comments, datapoint_id: @verification_history.datapoint_id, document_id: @verification_history.document_id, is_active: @verification_history.is_active, is_verified: @verification_history.is_verified, user_id: @verification_history.user_id, verification_dt: @verification_history.verification_dt } }
    end

    assert_redirected_to verification_history_url(VerificationHistory.last)
  end

  test "should show verification_history" do
    get verification_history_url(@verification_history)
    assert_response :success
  end

  test "should get edit" do
    get edit_verification_history_url(@verification_history)
    assert_response :success
  end

  test "should update verification_history" do
    patch verification_history_url(@verification_history), params: { verification_history: { comments: @verification_history.comments, datapoint_id: @verification_history.datapoint_id, document_id: @verification_history.document_id, is_active: @verification_history.is_active, is_verified: @verification_history.is_verified, user_id: @verification_history.user_id, verification_dt: @verification_history.verification_dt } }
    assert_redirected_to verification_history_url(@verification_history)
  end

  test "should destroy verification_history" do
    assert_difference('VerificationHistory.count', -1) do
      delete verification_history_url(@verification_history)
    end

    assert_redirected_to verification_histories_url
  end
end
