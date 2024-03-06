require "application_system_test_case"

class SummatoriesTest < ApplicationSystemTestCase
  setup do
    @summatory = summatories(:one)
  end

  test "visiting the index" do
    visit summatories_url
    assert_selector "h1", text: "Summatories"
  end

  test "should create summatory" do
    visit summatories_url
    click_on "New summatory"

    fill_in "Count sum", with: @summatory.count_sum
    click_on "Create Summatory"

    assert_text "Summatory was successfully created"
    click_on "Back"
  end

  test "should update Summatory" do
    visit summatory_url(@summatory)
    click_on "Edit this summatory", match: :first

    fill_in "Count sum", with: @summatory.count_sum
    click_on "Update Summatory"

    assert_text "Summatory was successfully updated"
    click_on "Back"
  end

  test "should destroy Summatory" do
    visit summatory_url(@summatory)
    click_on "Destroy this summatory", match: :first

    assert_text "Summatory was successfully destroyed"
  end
end
