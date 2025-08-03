#!/usr/bin/env ruby

# Script to clean up duplicate "Circular CNBS" documents
# Usage: rails runner scripts/cleanup_cnbs_duplicates.rb

puts "=" * 60
puts "CNBS Duplicate Cleanup Script"
puts "=" * 60
puts

# Find the Circular CNBS document type
cnbs_type = DocumentType.find_by(name: 'Circular CNBS')

unless cnbs_type
  puts "❌ ERROR: 'Circular CNBS' document type not found!"
  puts "Available document types:"
  DocumentType.all.each { |dt| puts "  - #{dt.name}" }
  exit 1
end

puts "✅ Found 'Circular CNBS' document type (ID: #{cnbs_type.id})"
puts

# Helper method to process duplicate documents
def process_duplicate_documents(documents, identifier, dry_run: true)
  return if documents.count <= 1
  
  # Separate documents with and without attachments
  docs_without_attachments = documents.reject { |doc| doc.original_file.attached? }
  docs_with_attachments = documents.select { |doc| doc.original_file.attached? }
  
  puts "  📋 Found #{documents.count} duplicates for #{identifier}"
  puts "     - #{docs_without_attachments.count} without attachments"
  puts "     - #{docs_with_attachments.count} with attachments"
  
  # Plan: Delete documents without attachments first
  docs_without_attachments.each do |doc|
    action = dry_run ? "[DRY RUN]" : "[DELETING]"
    puts "  🗑️  #{action} Document ID: #{doc.id} (#{identifier}, no file attachment)"
    unless dry_run
      doc.destroy!
    end
  end
  
  # Plan: Among documents with attachments, keep the oldest one
  if docs_with_attachments.length > 1
    # Sort by created_at to ensure we keep the oldest
    sorted_with_attachments = docs_with_attachments.sort_by(&:created_at)
    docs_to_delete = sorted_with_attachments.drop(1)  # Remove first (oldest), keep the rest
    
    docs_to_delete.each do |doc|
      action = dry_run ? "[DRY RUN]" : "[DELETING]"
      puts "  🗑️  #{action} Document ID: #{doc.id} (#{identifier}, keeping oldest with attachment)"
      unless dry_run
        doc.destroy!
      end
    end
    
    if dry_run
      oldest = sorted_with_attachments.first
      puts "  ✅ [DRY RUN] Would keep Document ID: #{oldest.id} (oldest with attachment)"
    end
  end
  
  puts
end

# Find duplicates by issue_id (when issue_id is present and not empty)
puts "🔍 Searching for issue_id duplicates..."

issue_id_duplicates = Document.where(document_type: cnbs_type)
                             .where.not(issue_id: [nil, ''])
                             .group(:issue_id)
                             .having('COUNT(*) > 1')
                             .pluck(:issue_id)

puts "Found #{issue_id_duplicates.count} issue_id groups with duplicates"
puts

# Find duplicates by description (when issue_id is null or empty)
puts "🔍 Searching for description duplicates..."

description_duplicates = Document.where(document_type: cnbs_type)
                                .where(issue_id: [nil, ''])
                                .where.not(description: [nil, ''])
                                .group(:description)
                                .having('COUNT(*) > 1')
                                .pluck(:description)

puts "Found #{description_duplicates.count} description groups with duplicates"
puts

total_groups = issue_id_duplicates.count + description_duplicates.count

if total_groups == 0
  puts "🎉 No duplicates found! Database is clean."
  exit 0
end

puts "📊 SUMMARY:"
puts "  - #{issue_id_duplicates.count} issue_id duplicate groups"
puts "  - #{description_duplicates.count} description duplicate groups"
puts "  - #{total_groups} total groups to process"
puts

# Ask for confirmation
puts "⚠️  This script will:"
puts "   1. Delete documents WITHOUT file attachments"
puts "   2. Among documents WITH attachments, keep the oldest and delete newer ones"
puts

print "Do you want to run a DRY RUN first? (Y/n): "
response = gets.chomp
dry_run = response.downcase != 'n'

if dry_run
  puts "\n🧪 RUNNING DRY RUN (no actual deletions)..."
else
  puts "\n💥 RUNNING LIVE CLEANUP (WILL DELETE DOCUMENTS)..."
  print "Are you absolutely sure? Type 'YES' to confirm: "
  confirmation = gets.chomp
  unless confirmation == 'YES'
    puts "❌ Aborted."
    exit 0
  end
end

puts "\n" + "=" * 60
puts "PROCESSING DUPLICATES"
puts "=" * 60

total_processed = 0

# Process issue_id duplicates
if issue_id_duplicates.any?
  puts "\n📋 Processing issue_id duplicates..."
  
  issue_id_duplicates.each do |issue_id|
    documents = Document.where(document_type: cnbs_type, issue_id: issue_id)
                       .order(:created_at)
    
    process_duplicate_documents(documents, "issue_id: #{issue_id}", dry_run: dry_run)
    total_processed += 1
  end
end

# Process description duplicates
if description_duplicates.any?
  puts "\n📋 Processing description duplicates..."
  
  description_duplicates.each do |description|
    documents = Document.where(document_type: cnbs_type)
                       .where(issue_id: [nil, ''])
                       .where(description: description)
                       .order(:created_at)
    
    process_duplicate_documents(documents, "description: #{description}", dry_run: dry_run)
    total_processed += 1
  end
end

puts "=" * 60
if dry_run
  puts "🧪 DRY RUN COMPLETED"
  puts "   - Processed #{total_processed} duplicate groups"
  puts "   - No actual changes were made"
  puts "   - Run again with 'n' to perform actual cleanup"
else
  puts "✅ CLEANUP COMPLETED"
  puts "   - Processed #{total_processed} duplicate groups"
  puts "   - Duplicates have been removed"
end
puts "=" * 60
