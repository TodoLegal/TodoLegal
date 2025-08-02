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
    
    # Delete processed files after successful processing
    if @result.success_count > 0
      Rails.logger.info "Processing completed with #{@result.success_count} successful documents. Starting file cleanup..."
      cleanup_result = delete_processed_files(json_data["files"])
      Rails.logger.info "Cleanup result: #{cleanup_result}"
    else
      Rails.logger.info "No successful documents processed. Skipping file cleanup."
    end
    
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
    # Handle documents with valid issue_id
    if attributes[:issue_id].present? && attributes[:issue_id].to_s.strip != ""
      existing = Document.where(
        issue_id: attributes[:issue_id].to_s.strip,
        document_type_id: attributes[:document_type_id]
      ).exists?
      
      if existing
        Rails.logger.info "Duplicate found by issue_id: issue_id='#{attributes[:issue_id]}', document_type_id='#{attributes[:document_type_id]}'"
      end
      
      return existing
    end
    
    # Handle documents with empty/blank issue_id - check by description and document_type
    if attributes[:description].present? && attributes[:description].to_s.strip != ""
      existing = Document.where(
        document_type_id: attributes[:document_type_id]
      ).where(
        "(issue_id IS NULL OR issue_id = '' OR TRIM(issue_id) = '') AND TRIM(description) = ?",
        attributes[:description].to_s.strip
      ).exists?
      
      if existing
        Rails.logger.info "Duplicate found by description: document_type_id='#{attributes[:document_type_id]}', description='#{attributes[:description].to_s.strip.truncate(100)}'"
      end
      
      return existing
    end
    
    # If both issue_id and description are blank, log warning but don't block creation
    Rails.logger.warn "Document has both blank issue_id and description - cannot check for duplicates effectively"
    false
  end

  def create_document(attributes)
    # Use database transaction with constraint handling
    Document.transaction do
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
  rescue ActiveRecord::RecordNotUnique => e
    # Handle database constraint violation
    Rails.logger.warn "Duplicate document prevented by database constraint: issue_id='#{attributes[:issue_id]}', document_type_id='#{attributes[:document_type_id]}'"
    @result.add_error("Duplicate document: #{attributes[:issue_id]} already exists")
    nil
  rescue => e
    Rails.logger.error "Unexpected error creating document: #{e.message}"
    @result.add_error("Error creating document: #{e.message}")
    nil
  end

  def add_document_tags(document, file_data)
    # Add issuer as issuer tag if present
    addIssuerTagIfExists(document.id, file_data['issuer']) if file_data['issuer'].present?

    # Add materia tag
    materia_tag = Tag.find_by(name: 'Bancario')
    addTagIfExists(document.id, materia_tag.name) if materia_tag

    # Add Forma de Publicacion tag
    forma_publicacion_tag = Tag.find_by(name: "Circular CNBS")
    addTagIfExists(document.id, forma_publicacion_tag.name) if forma_publicacion_tag

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
      # Handle Spanish date format like "19 de enero de 2022"
      if date_string.match?(/\d+\s+de\s+\w+\s+de\s+\d+/)
        spanish_months = {
          'enero' => 'January',
          'febrero' => 'February',
          'marzo' => 'March',
          'abril' => 'April',
          'mayo' => 'May',
          'junio' => 'June',
          'julio' => 'July',
          'agosto' => 'August',
          'septiembre' => 'September',
          'octubre' => 'October',
          'noviembre' => 'November',
          'diciembre' => 'December'
        }
        
        # Convert Spanish month names to English
        english_date = date_string.dup
        spanish_months.each do |spanish, english|
          english_date.gsub!(spanish, english)
        end
        
        # Remove "de" words and clean up
        english_date = english_date.gsub(/\s+de\s+/, ' ').strip
        
        Date.parse(english_date)&.strftime("%Y-%m-%d")
      else
        # Try parsing as-is for other formats
        Date.parse(date_string)&.strftime("%Y-%m-%d")
      end
    rescue => e
      Rails.logger.warn "Could not parse date '#{date_string}': #{e.message}, setting to nil"
      nil
    end
  end

  def get_uploader_name
    return nil unless @current_user
    "#{@current_user.first_name} #{@current_user.last_name}"
  end

  def delete_processed_files(files)
    Rails.logger.info "Starting file cleanup after batch processing"
    Rails.logger.info "Total files to process: #{files.length}"
    deleted_count = 0
    error_count = 0
    skipped_count = 0

    files.each_with_index do |file_data, index|
      file_path = file_data['path']
      
      Rails.logger.info "Processing file #{index + 1}: #{file_path}"
      
      if file_path.blank?
        Rails.logger.warn "File #{index + 1}: No path provided"
        skipped_count += 1
        next
      end
      
      # Convert relative path to absolute path
      # Handle different relative path patterns
      absolute_path = if file_path.start_with?('/')
                        # Already absolute path
                        file_path
                      else
                        # Convert relative path to absolute, relative to Rails root
                        File.expand_path(file_path, Rails.root)
                      end
      
      # Additional check: if the resolved path doesn't exist, try alternative patterns
      unless File.exist?(absolute_path)
        # Try with different relative patterns
        alternative_patterns = [
          file_path.gsub('../GazetteSlicer/', '../../../GazetteSlicer/'),
          file_path.gsub('../../../GazetteSlicer/', '../GazetteSlicer/'),
          file_path.gsub('../GazetteSlicer/', '../../GazetteSlicer/'),
          file_path.gsub('../../GazetteSlicer/', '../GazetteSlicer/')
        ].uniq.reject { |p| p == file_path }
        
        alternative_patterns.each do |alt_path|
          alt_absolute = File.expand_path(alt_path, Rails.root)
          if File.exist?(alt_absolute)
            Rails.logger.info "Found file using alternative path: #{alt_path} -> #{alt_absolute}"
            absolute_path = alt_absolute
            break
          end
        end
      end
      
      unless File.exist?(absolute_path)
        Rails.logger.warn "File #{index + 1}: File does not exist at path: #{absolute_path}"
        skipped_count += 1
        next
      end

      begin
        # Delete the main file
        File.delete(absolute_path)
        deleted_count += 1
        Rails.logger.info "Successfully deleted file: #{absolute_path}"
        
        # Also try to delete file with same name in data directory
        filename = File.basename(absolute_path)
        
        # Both stamped_documents and data are in the same GazetteSlicer directory
        # Just replace stamped_documents with data  in the path
        data_path = absolute_path.gsub('/stamped_documents/', '/data/')
        if File.exist?(data_path)
          begin
            if File.readable?(data_path) && File.writable?(data_path)
              File.delete(data_path)
              Rails.logger.info "Successfully deleted corresponding data file: #{data_path}"
              deleted_count += 1
            else
              Rails.logger.warn "Permission denied for data file: #{data_path}"
            end
          rescue => data_error
            Rails.logger.warn "Error deleting data file #{data_path}: #{data_error.message}"
          end
        else
          Rails.logger.warn "Data file not found: #{data_path}"
        end
        
      rescue => e
        error_count += 1
        Rails.logger.error "Error deleting file #{absolute_path}: #{e.class} - #{e.message}"
        Rails.logger.error "Backtrace: #{e.backtrace.first(3).join(', ')}"
      end
    end

    Rails.logger.info "File cleanup completed: #{deleted_count} files deleted, #{error_count} errors, #{skipped_count} skipped"
    
    # Return summary for debugging
    {
      deleted: deleted_count,
      errors: error_count,
      skipped: skipped_count,
      total: files.length
    }
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
