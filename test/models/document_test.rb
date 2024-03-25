require 'test_helper'

class DocumentTest < ActiveSupport::TestCase
  setup do
    @document = documents(:one)
  end

  test "searchkick indexes the expected fields" do
    results = Document.search(@document.name)
    assert_includes results, @document, "The document should be found by its name"
  end
end
