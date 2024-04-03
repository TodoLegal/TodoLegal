require 'test_helper'

class DocumentTest < ActiveSupport::TestCase
  setup do
    @document = documents(:one)
    @other_document = documents(:two)
    @publication_number_document = documents(:publication_number)
    @issue_id_document = documents(:issue_id)

    @nonexistent_document_name = "This Name Does Not Exist"
    @nonexistent_description = "Nonexistent Description"
    @nonexistent_short_description = "This Short Description Does Not Exist"
    Document.reindex
  end

  # Group: Searching by Document Attributes
  # Tests document search functionality based on various attributes (name, description, short description)

  # Test: Search by Name
  test "document can be found by its name" do
    results = Document.search(@document.name)
    assert_includes results, @document, "The document should be found by its name"
  end

  test "document with a nonexistent name is not present in the results" do
    results = Document.search(@nonexistent_document_name)
    refute_includes results, @existing_document, "A document with a nonexistent name should not be present in the results"
    assert_empty results, "No results should be returned for a nonexistent document name"
  end

  # Test: Search by Description
  test "document can be found by its description" do
    results = Document.search(@document.description)
    assert_includes results, @document, "The document should be found by its description"
  end

  test "document with a nonexistent description is not present in the results" do
    results = Document.search(@nonexistent_description)
    refute_includes results, @document, "A document with a nonexistent description should not be present in the results"
    assert_empty results, "No results should be returned for a nonexistent description"
  end

  # Test: Search by Short Description
  test "document can be found by its short_description" do
    results = Document.search(@document.short_description)
    assert_includes results, @document, "The document should be found by its short_description"
  end

  test "document with a nonexistent short_description is not present in the results" do
    results = Document.search(@nonexistent_short_description)
    refute_includes results, @document, "A document with a nonexistent short_description should not be present in the results"
    assert_empty results, "No results should be returned for a nonexistent short_description"
  end

  # Group: Searching by Publication Date
  # Tests focus on document retrieval based on formatted publication dates

  test "should find document by publication date with dashes format" do
    query_with_dashes = @document.publication_date.strftime('%d-%m-%Y') # "20-03-2020"
    results = Document.search(query_with_dashes, fields: [:publication_date])
    assert_includes results, @document, "The document should be found by its publication date using 'dd-mm-yyyy' format"
  end

  test "should find document by publication date with slashes format" do
    query_with_slashes = @document.publication_date.strftime('%d/%m/%Y') # "20/03/2020"
    results = Document.search(query_with_slashes, fields: [:publication_date_slash])
    assert_includes results, @document, "The document should be found by its publication date using 'dd/mm/yyyy' format"
  end

  test "document with the exact matching publication_date has the highest priority" do
    significant_date = '2020-03-20'
    query = significant_date

    results = Document.search(query)

    # Verify the document with the exact matching publication_date is prioritized
    assert_equal results.first.publication_date.strftime('%Y-%m-%d'), significant_date, "The document with the exact matching publication date should come first"
  end

  test "searching by issue_id returns the correct document" do
    search_term = @issue_id_document.issue_id
    results = Document.search(search_term)

    assert_not results.empty?, "The search should return at least one document."
    assert_equal documents(:issue_id).id, results.first.id, "The search should return the document with issue_id '36,111'."
  end

  test "should find document by specific publication_number" do
    search_term = @publication_number_document.publication_number
    results = Document.search(search_term)

    assert_not results.empty?, "The search should return at least one document for the publication_number '#{search_term}'."
    assert_equal @publication_number_document.id, results.first.id, "The search should return the correct document with publication_number '#{search_term}'."
  end

  test "documents are found by associated tag names" do
    document_with_tag = documents(:one)
    results = Document.search(document_with_tag.tags.first.name)

    assert_not results.empty?, "Expected to find documents."
    assert_includes results.map(&:id), document_with_tag.id, "Document associated with 'Penal' tag should be found."
  end

  test "documents are found by multiple associated tag names" do
    document_with_tags = documents(:two)
    results = Document.search(document_with_tags.tags.map(&:name).join(' '))

    assert_not results.empty?, "Expected to find documents."
    assert_includes results.map(&:id), document_with_tags.id, "Document associated with multiple tags should be found."
  end

  test "should find document by associated issuer document tag name 'Penal'" do
    search_term = documents(:one).issuer_document_tags.first.tag.name
    results = Document.search(search_term)

    assert_not results.empty?, "Expected to find documents by tag name."
    assert_includes results.map(&:id), documents(:one).id, "Document with the 'Penal' tag should be found."
  end

  test "should find document by document_type name" do
    search_term = documents(:one).document_type.name # 'Oficio'
    results = Document.search(search_term)

    assert_not results.empty?, "Expected to find documents with document type '#{search_term}'."
    results.each do |document|
      assert_equal search_term, document.document_type.name, "Found document should have '#{search_term}' document type."
    end
  end

  test "should find document by document_type's alternative_name" do
    alternative_name = documents(:auto).document_type.alternative_name
    search_term = "#{alternative_name}"

    results = Document.search(search_term)

    assert_not results.empty?, "Expected to find documents by alternative_name."
    found_by_alternative_name = results.any? { |doc| doc.document_type.alternative_name == alternative_name }
    assert found_by_alternative_name , "Document should be found by document_type's alternative_name."
  end

  test 'should find only published documents' do
    results = Document.search('*', where: { publish: true })

    assert_not results.empty?, 'Expected to find published documents.'
    results.each do |document|
      assert document.publish, 'Each found document should be published.'
    end
  end

  test 'should not find unpublished documents when filtering for published' do
    results = Document.search('*', where: { publish: true })

    results.each do |document|
      refute_equal false, document.publish, 'Unpublished documents should not be found.'
    end
  end
end
