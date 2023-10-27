require "application_system_test_case"

class DatapointsTest < ApplicationSystemTestCase
  setup do
    @datapoint = datapoints(:one)
  end

  test "visiting the index" do
    visit datapoints_url
    assert_selector "h1", text: "Datapoints"
  end

  test "creating a Datapoint" do
    visit datapoints_url
    click_on "New Datapoint"

    fill_in "Name", with: @datapoint.name
    fill_in "Priority", with: @datapoint.priority
    fill_in "User permission", with: @datapoint.user_permission_id
    click_on "Create Datapoint"

    assert_text "Datapoint was successfully created"
    click_on "Back"
  end

  test "updating a Datapoint" do
    visit datapoints_url
    click_on "Edit", match: :first

    fill_in "Name", with: @datapoint.name
    fill_in "Priority", with: @datapoint.priority
    fill_in "User permission", with: @datapoint.user_permission_id
    click_on "Update Datapoint"

    assert_text "Datapoint was successfully updated"
    click_on "Back"
  end

  test "destroying a Datapoint" do
    visit datapoints_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Datapoint was successfully destroyed"
  end
end
