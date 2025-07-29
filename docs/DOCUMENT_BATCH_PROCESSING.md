# Document JSON Batch Processing

This feature allows for batch processing of documents from a JSON file, creating Document records with proper attributes and file attachments.

## Overview

The `DocumentJsonBatchProcessor` service provides a clean, maintainable way to process JSON files containing document information and create corresponding database records.

## Usage

### Controller Method

```ruby
def process_document_json_batch
  processor = DocumentJsonBatchProcessor.new(current_user)
  result = processor.process('processed_files.json')
  
  # Handle the result...
end
```

### Expected JSON Format

The JSON file should contain a `files` array with document objects:

```json
{
  "files": [
    {
      "document_type": "Decreto",
      "issue_id": "DEC-001-2024",
      "date": "2024-01-15",
      "issuer": "Ministry of Justice",
      "description": "Document description here",
      "tags": ["Tag1", "Tag2"],
      "full_text": "Full document content...",
      "path": "/path/to/document.pdf"
    }
  ]
}
```

### Required Fields

- `document_type`: The type of document (must exist in DocumentType table)
- `path`: Path to the document file to be attached

### Optional Fields

- `issue_id`: Document identifier
- `date`: Publication date (various formats supported)
- `issuer`: Document issuer (added as issuer tag)
- `description`: Document description
- `tags`: Array of tags to associate with the document
- `full_text`: Full document text content

## Features

### Error Handling
- Validates required fields before processing
- Checks for duplicate documents
- Handles file attachment errors gracefully
- Provides detailed error reporting

### Data Processing
- Normalizes document type names for consistent lookup
- Parses dates in various formats
- Cleans text content
- Creates appropriate tags and issuer tags

### Logging
- Comprehensive logging for debugging and monitoring
- Error tracking with detailed messages
- Processing statistics

## Architecture

### Service Object Pattern
The `DocumentJsonBatchProcessor` follows the service object pattern, encapsulating the batch processing logic in a dedicated class.

### Concerns
The `DocumentTagManagement` concern provides reusable methods for tag and document type handling.

### Result Object
The `ProcessingResult` class tracks success/error counts and provides a summary of the processing operation.

## Best Practices

1. **Validation**: Always validate required fields before processing
2. **Error Handling**: Gracefully handle errors without stopping the entire batch
3. **Logging**: Use Rails.logger for consistent logging
4. **Transactions**: Consider wrapping document creation in transactions for data integrity
5. **File Handling**: Verify file existence before attempting to attach

## Testing

Tests are provided in `test/services/document_json_batch_processor_test.rb` covering:
- Successful processing
- Error handling
- Edge cases
- Invalid input handling

## Monitoring

The service provides detailed statistics including:
- Number of documents successfully processed
- Number of errors encountered
- Detailed error messages for debugging

## Example Usage

```ruby
# In controller
processor = DocumentJsonBatchProcessor.new(current_user)
result = processor.process('batch_file.json')

if result.successful?
  flash[:notice] = "Successfully processed #{result.success_count} documents"
else
  flash[:alert] = "Processed #{result.success_count} documents with #{result.error_count} errors"
  Rails.logger.error "Batch errors: #{result.errors.join('; ')}"
end
```
