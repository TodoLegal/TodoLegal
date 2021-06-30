require "application_system_test_case"

class LawModificationsTest < ApplicationSystemTestCase
  setup do
    @law_modification = law_modifications(:one)
  end

  test "visiting the index" do
    visit law_modifications_url
    assert_selector "h1", text: "Law Modifications"
  end

  test "creating a Law modification" do
    visit law_modifications_url
    click_on "New Law Modification"

    fill_in "Law", with: @law_modification.law_id
    fill_in "Name", with: @law_modification.name
    click_on "Create Law modification"

    assert_text "Law modification was successfully created"
    click_on "Back"
  end

  test "updating a Law modification" do
    visit law_modifications_url
    click_on "Edit", match: :first

    fill_in "Law", with: @law_modification.law_id
    fill_in "Name", with: @law_modification.name
    click_on "Update Law modification"

    assert_text "Law modification was successfully updated"
    click_on "Back"
  end

  test "destroying a Law modification" do
    visit law_modifications_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Law modification was successfully destroyed"
  end
end
