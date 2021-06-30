require "application_system_test_case"

class LawTagsTest < ApplicationSystemTestCase
  setup do
    @law_tag = law_tags(:one)
  end

  test "visiting the index" do
    visit law_tags_url
    assert_selector "h1", text: "Law Tags"
  end

  test "creating a Law tag" do
    visit law_tags_url
    click_on "New Law Tag"

    fill_in "Law", with: @law_tag.law_id
    fill_in "Tag", with: @law_tag.tag_id
    click_on "Create Law tag"

    assert_text "Law tag was successfully created"
    click_on "Back"
  end

  test "updating a Law tag" do
    visit law_tags_url
    click_on "Edit", match: :first

    fill_in "Law", with: @law_tag.law_id
    fill_in "Tag", with: @law_tag.tag_id
    click_on "Update Law tag"

    assert_text "Law tag was successfully updated"
    click_on "Back"
  end

  test "destroying a Law tag" do
    visit law_tags_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Law tag was successfully destroyed"
  end
end
