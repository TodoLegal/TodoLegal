require 'test_helper'

class DocumentTest < ActiveSupport::TestCase
  setup do
    @document = documents(:one)
    @nonexistent_document_name = "This Name Does Not Exist"
    @nonexistent_description = "Nonexistent Description"
    @nonexistent_short_description = "This Short Description Does Not Exist"
    Document.reindex
  end

  test "document can be found by its name" do
    results = Document.search(@document.name)
    assert_includes results, @document, "The document should be found by its name"
  end

  test "document with a nonexistent name is not present in the results" do
    results = Document.search(@nonexistent_document_name)
    refute_includes results, @existing_document, "A document with a nonexistent name should not be present in the results"
    assert_empty results, "No results should be returned for a nonexistent document name"
  end

  test "document can be found by its description" do
    results = Document.search(@document.description)
    assert_includes results, @document, "The document should be found by its description"
  end

  test "document with a nonexistent description is not present in the results" do
    results = Document.search(@nonexistent_description)
    refute_includes results, @document, "A document with a nonexistent description should not be present in the results"
    assert_empty results, "No results should be returned for a nonexistent description"
  end

  test "document can be found by its short_description" do
    results = Document.search(@document.short_description)
    assert_includes results, @document, "The document should be found by its short_description"
  end

  test "document with a nonexistent short_description is not present in the results" do
    results = Document.search(@nonexistent_short_description)
    refute_includes results, @document, "A document with a nonexistent short_description should not be present in the results"
    assert_empty results, "No results should be returned for a nonexistent short_description"
  end
end
