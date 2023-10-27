require "application_system_test_case"

class VerificationHistoriesTest < ApplicationSystemTestCase
  setup do
    @verification_history = verification_histories(:one)
  end

  test "visiting the index" do
    visit verification_histories_url
    assert_selector "h1", text: "Verification Histories"
  end

  test "creating a Verification history" do
    visit verification_histories_url
    click_on "New Verification History"

    fill_in "Comments", with: @verification_history.comments
    fill_in "Datapoint", with: @verification_history.datapoint_id
    fill_in "Document", with: @verification_history.document_id
    check "Is active" if @verification_history.is_active
    check "Is verified" if @verification_history.is_verified
    fill_in "User", with: @verification_history.user_id
    fill_in "Verification dt", with: @verification_history.verification_dt
    click_on "Create Verification history"

    assert_text "Verification history was successfully created"
    click_on "Back"
  end

  test "updating a Verification history" do
    visit verification_histories_url
    click_on "Edit", match: :first

    fill_in "Comments", with: @verification_history.comments
    fill_in "Datapoint", with: @verification_history.datapoint_id
    fill_in "Document", with: @verification_history.document_id
    check "Is active" if @verification_history.is_active
    check "Is verified" if @verification_history.is_verified
    fill_in "User", with: @verification_history.user_id
    fill_in "Verification dt", with: @verification_history.verification_dt
    click_on "Update Verification history"

    assert_text "Verification history was successfully updated"
    click_on "Back"
  end

  test "destroying a Verification history" do
    visit verification_histories_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Verification history was successfully destroyed"
  end
end
