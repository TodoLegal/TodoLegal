require 'test_helper'

class DocumentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @document = documents(:one)
  end

  test "should get index" do
    get documents_url
    assert_response :success
  end

  test "should get new" do
    get new_document_url
    assert_response :success
  end

  test "should create document" do
    assert_difference('Document.count') do
      post documents_url, params: { document: { name: @document.name } }
    end

    assert_redirected_to document_url(Document.last)
  end

  test "should show document" do
    get document_url(@document)
    assert_response :success
  end

  test "should get edit" do
    get edit_document_url(@document)
    assert_response :success
  end

  test "should update document" do
    patch document_url(@document), params: { document: { name: @document.name } }
    assert_redirected_to document_url(@document)
  end

  test "should update document, set publish to true, and redirect to next document" do
    new_name = "New Document Name"
    
    # Stub the get_next_document method to return a specific document
    next_document = documents(:two)
    DocumentsController.any_instance.stubs(:get_next_document).returns(next_document)
  
    patch document_url(@document), params: { document: { name: new_name, publish: true }, commit: "Guardar y siguiente" }
    @document.reload
  
    assert_equal new_name, @document.name
    assert_equal true, @document.publish
    assert_redirected_to edit_document_url(next_document)
  end

  test "should destroy document" do
    assert_difference('Document.count', -1) do
      delete document_url(@document)
    end

    assert_redirected_to documents_url
  end
end
