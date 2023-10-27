require "application_system_test_case"

class LawsTest < ApplicationSystemTestCase
  setup do
    @law = laws(:one)
  end

  test "visiting the index" do
    visit laws_url
    assert_selector "h1", text: "Laws"
  end

  test "creating a Law" do
    visit laws_url
    click_on "New Law"

    fill_in "Name", with: @law.name
    click_on "Create Law"

    assert_text "Law was successfully created"
    click_on "Back"
  end

  test "updating a Law" do
    visit laws_url
    click_on "Edit", match: :first

    fill_in "Name", with: @law.name
    click_on "Update Law"

    assert_text "Law was successfully updated"
    click_on "Back"
  end

  test "destroying a Law" do
    visit laws_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Law was successfully destroyed"
  end
end
