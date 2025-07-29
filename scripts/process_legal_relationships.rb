#!/usr/bin/env ruby
# Script to process legal relationships from JSON file
# Usage: rails runner scripts/process_legal_relationships.rb [json_file_path]

class LegalRelationshipProcessor
  def initialize(json_file_path = nil)
    @json_file_path = json_file_path || Rails.root.join('..', 'GazetteSlicer', 'legal_relationships.json')
    @stats = {
      processed: 0,
      relationships_created: 0,
      documents_not_found: 0,
      target_documents_not_found: 0,
      errors: 0,
      skipped_empty_issue_id: 0
    }
    @errors_log = []
  end

  def process!
    puts "🔄 Processing legal relationships from: #{@json_file_path}"
    puts "=" * 60
    
    unless File.exist?(@json_file_path)
      puts "❌ JSON file not found: #{@json_file_path}"
      return false
    end

    begin
      data = JSON.parse(File.read(@json_file_path))
      documents = data['documents'] || []
      
      puts "📊 Found #{documents.size} documents to process"
      puts
      
      documents.each_with_index do |doc_data, index|
        process_document(doc_data, index + 1, documents.size)
      end
      
      print_summary
      
    rescue JSON::ParserError => e
      puts "❌ Invalid JSON format: #{e.message}"
      return false
    rescue => e
      puts "❌ Unexpected error: #{e.message}"
      puts e.backtrace.first(5)
      return false
    end
    
    true
  end

  private

  def process_document(doc_data, current, total)
    issue_id = doc_data['issue_id']&.strip
    
    # Skip documents without issue_id
    if issue_id.blank?
      @stats[:skipped_empty_issue_id] += 1
      puts "⚠️  [#{current}/#{total}] Skipping document without issue_id"
      return
    end

    print "🔍 [#{current}/#{total}] Processing #{issue_id}... "
    
    # Find the current document/law
    current_item = find_document_or_law(issue_id, doc_data['document_type'])
    
    unless current_item
      @stats[:documents_not_found] += 1
      puts "❌ Document/Law not found"
      @errors_log << "Document/Law not found: #{issue_id} (#{doc_data['document_type']})"
      return
    end

    relationships_count = 0
    
    # Process 'amends' relationships (current item is SOURCE, amends others)
    doc_data['amends']&.each do |target_issue_id|
      if create_modification_relationship(current_item, target_issue_id, 'amend', 'source')
        relationships_count += 1
      end
    end
    
    # Process 'repeals' relationships (current item is SOURCE, repeals others)  
    doc_data['repeals']&.each do |target_issue_id|
      if create_modification_relationship(current_item, target_issue_id, 'repeal', 'source')
        relationships_count += 1
      end
    end
    
    # Process 'amended_by' relationships (current item is TARGET, amended by others)
    doc_data['amended_by']&.each do |source_issue_id|
      if create_modification_relationship(current_item, source_issue_id, 'amend', 'target')
        relationships_count += 1
      end
    end
    
    # Process 'repealed_by' relationships (current item is TARGET, repealed by others)
    doc_data['repealed_by']&.each do |source_issue_id|
      if create_modification_relationship(current_item, source_issue_id, 'repeal', 'target')
        relationships_count += 1
      end
    end

    # Update status if the document/law is repealed
    if doc_data['repealed'] == 'true' || doc_data['repealed'] == true
      update_status_to_repealed(current_item)
    end

    @stats[:processed] += 1
    puts "✅ Created #{relationships_count} relationships"
    
  rescue => e
    @stats[:errors] += 1
    error_msg = "Error processing #{issue_id}: #{e.message}"
    puts "❌ #{error_msg}"
    @errors_log << error_msg
  end

  def find_document_or_law(issue_id, document_type = nil)
    # First try to find in Documents table
    doc = find_document(issue_id, document_type)
    return doc if doc
    
    # If not found in documents, try Laws table
    law = find_law(issue_id)
    return law if law
    
    nil
  end

  def find_document(issue_id, document_type = nil)
    # First try exact match by issue_id
    doc = Document.find_by(issue_id: issue_id)
    return doc if doc
    
    # Try fuzzy matching for common variations
    variations = generate_issue_id_variations(issue_id)
    variations.each do |variation|
      doc = Document.find_by(issue_id: variation)
      return doc if doc
    end
    
    nil
  end

  def find_law(issue_id)
    # Try to find by creation_number (most common identifier for laws)
    law = Law.find_by(creation_number: issue_id)
    return law if law
    
    # Try by name if creation_number doesn't work
    law = Law.find_by(name: issue_id)
    return law if law
    
    # Try fuzzy matching for laws
    variations = generate_issue_id_variations(issue_id)
    variations.each do |variation|
      law = Law.find_by(creation_number: variation) || Law.find_by(name: variation)
      return law if law
    end
    
    nil
  end

  def generate_issue_id_variations(issue_id)
    variations = []
    
    # Remove/add spaces around slashes
    variations << issue_id.gsub(/\s*\/\s*/, '/')
    variations << issue_id.gsub(/\//, ' /')
    variations << issue_id.gsub(/\//, '/ ')
    
    # Remove "No." prefix if present
    if issue_id.start_with?('No.')
      clean_id = issue_id.sub(/^No\./, '').strip
      variations << clean_id
      variations << "No. #{clean_id}"
    else
      variations << "No.#{issue_id}"
      variations << "No. #{issue_id}"
    end
    
    # Handle different date formats
    if issue_id.match(/\d{2}-\d{2}-\d{4}/)
      variations << issue_id.gsub(/-/, '/')
    elsif issue_id.match(/\d{2}\/\d{2}\/\d{4}/)
      variations << issue_id.gsub(/\//, '-')
    end
    
    variations.uniq
  end

  def create_modification_relationship(current_item, other_issue_id, modification_type, current_role)
    other_item = find_document_or_law(other_issue_id)
    
    unless other_item
      @stats[:target_documents_not_found] += 1
      @errors_log << "Target document/law not found: #{other_issue_id} (for #{modification_type} relationship)"
      return false
    end

    # Determine source and target based on the role of current_item
    if current_role == 'source'
      source_item = current_item
      target_item = other_item
    else # current_role == 'target'
      source_item = other_item  
      target_item = current_item
    end

    # Create appropriate relationship based on item types
    if source_item.is_a?(Document) && target_item.is_a?(Document)
      # Document-Document relationship
      relationship = DocumentRelationship.find_or_create_by(
        source_document: source_item,
        target_document: target_item,
        modification_type: modification_type
      )
      
      if relationship.persisted?
        @stats[:relationships_created] += 1
        return true
      end
      
    elsif source_item.is_a?(Document) && target_item.is_a?(Law)
      # Document-Law relationship (document modifies law)
      modification = LawModification.find_or_create_by(
        document: source_item,
        law: target_item,
        modification_type: modification_type,
        modification_date: Date.current
      )
      
      if modification.persisted?
        @stats[:relationships_created] += 1
        return true
      end
      
    elsif source_item.is_a?(Law) && target_item.is_a?(Document)
      # This case is uncommon but we'll log it
      @errors_log << "Unusual case: Law #{source_item.creation_number} trying to modify Document #{target_item.issue_id}"
      return false
      
    elsif source_item.is_a?(Law) && target_item.is_a?(Law)
      # Law-Law relationship (not currently supported, but we can log it)
      @errors_log << "Law-Law relationship not supported: #{source_item.creation_number} -> #{target_item.creation_number}"
      return false
    end
    
    @errors_log << "Failed to create relationship: #{current_item.class} -> #{other_item.class}"
    return false
  end

  def update_status_to_repealed(item)
    if item.is_a?(Document)
      item.update(status: 'derogado') if item.respond_to?(:status)
    end
  rescue => e
    @errors_log << "Failed to update status for #{item.class} #{item.id}: #{e.message}"
  end

  def print_summary
    puts
    puts "=" * 60
    puts "📈 PROCESSING SUMMARY"
    puts "=" * 60
    puts "✅ Documents processed: #{@stats[:processed]}"
    puts "🔗 Relationships created: #{@stats[:relationships_created]}"
    puts "❌ Documents/Laws not found: #{@stats[:documents_not_found]}"
    puts "🔍 Target documents/laws not found: #{@stats[:target_documents_not_found]}"
    puts "⚠️  Documents skipped (empty issue_id): #{@stats[:skipped_empty_issue_id]}"
    puts "🚨 Errors: #{@stats[:errors]}"
    
    if @errors_log.any?
      puts
      puts "🚨 ERROR DETAILS:"
      puts "-" * 40
      @errors_log.each { |error| puts "   • #{error}" }
    end
    
    puts
    success_rate = @stats[:processed] > 0 ? (@stats[:relationships_created].to_f / (@stats[:processed] * 4) * 100).round(2) : 0
    puts "📊 Overall success rate: #{success_rate}%"
    puts "=" * 60
  end
end

# Main execution
if __FILE__ == $0
  json_file = ARGV[0]
  processor = LegalRelationshipProcessor.new(json_file)
  
  start_time = Time.current
  success = processor.process!
  end_time = Time.current
  
  puts
  puts "⏱️  Processing completed in #{(end_time - start_time).round(2)} seconds"
  
  exit(success ? 0 : 1)
end
