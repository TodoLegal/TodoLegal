require 'test_helper'

class DocumentJsonBatchProcessorTest < ActiveSupport::TestCase
  def setup
    @processor = DocumentJsonBatchProcessor.new
    @test_json_file = Rails.root.join('tmp', 'test_processed_files.json')
  end

  def teardown
    File.delete(@test_json_file) if File.exist?(@test_json_file)
  end

  test "should process valid JSON file successfully" do
    # Create test JSON file
    test_data = {
      "files" => [
        {
          "document_type" => "Decreto",
          "issue_id" => "TEST-001",
          "date" => "2024-01-15",
          "issuer" => "Test Issuer",
          "description" => "Test document description",
          "tags" => ["Test Tag"],
          "full_text" => "This is test content",
          "path" => create_test_file
        }
      ]
    }
    
    File.write(@test_json_file, test_data.to_json)
    
    result = @processor.process(@test_json_file)
    
    assert result.successful?, "Processing should be successful"
    assert_equal 1, result.success_count, "Should process one document"
    assert_equal 0, result.error_count, "Should have no errors"
  end

  test "should handle missing required fields gracefully" do
    test_data = {
      "files" => [
        {
          "issue_id" => "TEST-002",
          "date" => "2024-01-15"
          # Missing document_type and path
        }
      ]
    }
    
    File.write(@test_json_file, test_data.to_json)
    
    result = @processor.process(@test_json_file)
    
    assert_not result.successful?, "Processing should fail with missing fields"
    assert_equal 0, result.success_count, "Should not process any documents"
    assert result.error_count > 0, "Should have errors"
  end

  test "should handle invalid JSON gracefully" do
    File.write(@test_json_file, "invalid json content")
    
    result = @processor.process(@test_json_file)
    
    assert_not result.successful?, "Processing should fail with invalid JSON"
    assert_equal 0, result.success_count, "Should not process any documents"
    assert result.error_count > 0, "Should have errors"
  end

  test "should handle missing file gracefully" do
    result = @processor.process('non_existent_file.json')
    
    assert_not result.successful?, "Processing should fail with missing file"
    assert_equal 0, result.success_count, "Should not process any documents"
    assert result.error_count > 0, "Should have errors"
  end

  private

  def create_test_file
    test_file_path = Rails.root.join('tmp', 'test_document.pdf')
    File.write(test_file_path, "test content")
    test_file_path.to_s
  end
end
