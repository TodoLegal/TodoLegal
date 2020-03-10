require "application_system_test_case"

class LawAccessesTest < ApplicationSystemTestCase
  setup do
    @law_access = law_accesses(:one)
  end

  test "visiting the index" do
    visit law_accesses_url
    assert_selector "h1", text: "Law Accesses"
  end

  test "creating a Law access" do
    visit law_accesses_url
    click_on "New Law Access"

    fill_in "Name", with: @law_access.name
    click_on "Create Law access"

    assert_text "Law access was successfully created"
    click_on "Back"
  end

  test "updating a Law access" do
    visit law_accesses_url
    click_on "Edit", match: :first

    fill_in "Name", with: @law_access.name
    click_on "Update Law access"

    assert_text "Law access was successfully updated"
    click_on "Back"
  end

  test "destroying a Law access" do
    visit law_accesses_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Law access was successfully destroyed"
  end
end
