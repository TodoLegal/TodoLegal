require 'test_helper'

class DocumentTest < ActiveSupport::TestCase
  setup do
    @document = documents(:one)
    @nonexistent_document_name = "This Name Does Not Exist"
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
end
