class DocumentJsonBatchProcessor
  include DocumentTagManagement
  include DocumentsHelper
  
  attr_reader :result

  def initialize(current_user = nil)
    @current_user = current_user
    @result = ProcessingResult.new
  end

  def process(json_file_path = 'processed_files.json')
    Rails.logger.info "Starting JSON batch processing from #{json_file_path}"
    
    json_data = load_json_data(json_file_path)
    return @result unless json_data

    process_documents(json_data["files"])
    @result
  end

  private

  def load_json_data(json_file_path)
    unless File.exist?(json_file_path)
      @result.add_error("JSON file not found: #{json_file_path}")
      return nil
    end

    begin
      JSON.parse(File.read(json_file_path))
    rescue JSON::ParserError => e
      @result.add_error("Invalid JSON format: #{e.message}")
      nil
    end
  end

  def process_documents(files)
    files.each_with_index do |file_data, index|
      process_single_document(file_data, index + 1)
    rescue => e
      Rails.logger.error "Error processing document #{index + 1}: #{e.message}"
      @result.add_error("Document #{index + 1}: #{e.message}")
    end
  end

  def process_single_document(file_data, document_number)
    Rails.logger.info "Processing document #{document_number}: #{file_data['issue_id'] || 'No Issue ID'}"
    
    # Ensure file_data is a hash
    unless file_data.is_a?(Hash)
      @result.add_error("Document #{document_number}: Invalid data format")
      return
    end
    
    # Extract and validate required fields
    document_attributes = extract_document_attributes(file_data)
    return unless validate_required_fields(document_attributes, document_number, file_data['path'])

    # Check for duplicates
    if duplicate_exists?(document_attributes)
      Rails.logger.info "Document already exists. Skipping..."
      return
    end

    # Create and save document
    document = create_document(document_attributes)
    return unless document&.persisted?

    # Add tags and issuer
    add_document_tags(document, file_data)
    
    # Attach file
    attach_document_file(document, file_data['path'], document_number)
    
    @result.increment_success
    Rails.logger.info "Document created successfully with ID: #{document.id}"
  end

  def extract_document_attributes(file_data)
    publication_date = parse_date(file_data['date'])

    {
      issue_id: file_data['issue_id'],
      publication_date: publication_date,
      description: cleanText(file_data['description']),
      full_text: cleanText(file_data['full_text']),
      document_type_id: get_document_type_id_by_name(file_data['document_type']),
      uploaded_by: get_uploader_name,
      publish: false
    }
  end

  def validate_required_fields(attributes, document_number, file_path = nil)
    missing_fields = []
    missing_fields << 'document_type' if attributes[:document_type_id].nil?
    missing_fields << 'file path' if file_path.blank?
    
    if missing_fields.any?
      error_msg = "Missing required fields (#{missing_fields.join(', ')})"
      Rails.logger.warn "Document #{document_number}: #{error_msg}"
      @result.add_error("Document #{document_number}: #{error_msg}")
      return false
    end
    true
  end

  def duplicate_exists?(attributes)
    # Use the existing helper method for consistency
    check_document_duplicity(nil, nil, attributes[:issue_id])
  end

  def create_document(attributes)
    document = Document.new(attributes.compact)
    
    if document.save
      document
    else
      error_msg = document.errors.full_messages.join(', ')
      Rails.logger.error "Error creating document: #{error_msg}"
      @result.add_error("Error creating document: #{error_msg}")
      nil
    end
  end

  def add_document_tags(document, file_data)
    # Add issuer as issuer tag if present
    addIssuerTagIfExists(document.id, file_data['issuer']) if file_data['issuer'].present?

    # Add materia tag
    materia_tag = Tag.find_by(name: 'Bancario')
    addTagIfExists(document.id, materia_tag.name) if materia_tag

    # Add tipo de acto tag
    tipo_acto_tag = Tag.find_by(name: "Circular CNBS")
    addTagIfExists(document.id, tipo_acto_tag.name) if tipo_acto_tag

    # Add each tag from the tags array
    tags = file_data['tags'] || []
    tags = [tags] unless tags.is_a?(Array) # Handle single tag as string
    
    tags.each do |tag|
      addTagIfExists(document.id, tag) if tag.present?
    end
  end

  def attach_document_file(document, file_path, document_number)
    return unless file_path.present?
    
    download_name = if document.issue_id.present?
                        document.issue_id
                      elsif document.respond_to?(:name) && document.name.present?
                        document.name
                      elsif document.document_type.present?
                        document.document_type.name
                      else
                        "document_#{document.id}"
                      end

    unless File.exist?(file_path)
      error_msg = "File not found at path: #{file_path}"
      Rails.logger.warn error_msg
      @result.add_error("Document #{document_number}: #{error_msg}")
      return
    end

    begin
      document.original_file.attach(
        io: File.open(file_path),
        filename: "#{download_name}.pdf",
        content_type: get_content_type(file_path)
      )
      Rails.logger.info "File attached successfully: #{download_name}"
    rescue => e
      error_msg = "Error attaching file: #{e.message}"
      Rails.logger.error error_msg
      @result.add_error("Document #{document.id}: #{error_msg}")
    end
  end

  # Helper methods that delegate to existing implementations
  def parse_date(date_string)
    return nil if date_string.blank?

    begin
      Date.parse(date_string)&.strftime("%Y-%m-%d")
    rescue
      Rails.logger.warn "Could not parse date '#{date_string}', setting to nil"
      nil
    end
  end

  def get_uploader_name
    return nil unless @current_user
    "#{@current_user.first_name} #{@current_user.last_name}"
  end

  # Result object to track processing statistics
  class ProcessingResult
    attr_reader :success_count, :errors

    def initialize
      @success_count = 0
      @errors = []
    end

    def increment_success
      @success_count += 1
    end

    def add_error(error_message)
      @errors << error_message
    end

    def error_count
      @errors.length
    end

    def successful?
      @errors.empty?
    end

    def summary
      "#{@success_count} documents created, #{error_count} errors"
    end
  end
end
