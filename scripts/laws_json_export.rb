#!/usr/bin/env ruby

# Script to export laws data as JSON
# Usage: 
#   rails runner scripts/laws_json_export.rb           # Full export
#   rails runner scripts/laws_json_export.rb --dry-run # Dry run (no file output)

require 'json'

def export_laws_to_json(dry_run: false)
  puts dry_run ? "DRY RUN: Previewing laws data export..." : "Exporting laws data to JSON..."
  
  # Find the materia tag type
  materia_tag_type = TagType.find_by(name: 'materia')
  
  unless materia_tag_type
    puts "Warning: 'materia' tag type not found. Available tag types:"
    TagType.all.each { |tt| puts "  - #{tt.name}" }
    return
  end
  
  # Query laws with their materia tags
  laws_data = Law.includes(
    :law_access,
    law_tags: { tag: :tag_type }
  ).map do |law|
    # Get materia tags for this law
    materia_tags = law.tags.where(tag_type: materia_tag_type)
    materia_names = materia_tags.pluck(:name).join(', ')
    
    # Determine revision date (using updated_at as proxy since no specific revision_date field exists)
    revision_date = law.updated_at&.strftime('%Y-%m-%d')
    
    {
      id: law.id,
      name: law.name,
      materias: materia_names,
      full_url: "https://todolegal.app/laws/#{law.friendly_url}",
      creation_number: law.creation_number,
      revision_date: revision_date,
    }
  end
  
  # Generate JSON
  json_output = {
    export_date: Time.current.strftime('%Y-%m-%d %H:%M:%S'),
    total_laws: laws_data.count,
    laws: laws_data
  }
  
  if dry_run
    # In dry run, only show first 3 laws as preview
    preview_data = json_output.dup
    preview_data[:laws] = laws_data.first(3)
    preview_data[:note] = "DRY RUN: Showing first 3 laws only"
    
    puts JSON.pretty_generate(preview_data)
    puts "\n#{'-' * 50}"
    puts "DRY RUN SUMMARY:"
    puts "Would export #{laws_data.count} laws"
    puts "No file would be created"
  else
    # Pretty print JSON
    puts JSON.pretty_generate(json_output)
    
    # Save to file
    output_file = "laws_export_#{Time.current.strftime('%Y%m%d_%H%M%S')}.json"
    File.write(output_file, JSON.pretty_generate(json_output))
    puts "\nJSON exported to: #{output_file}"
  end
  
  # Display summary
  puts "\nSummary:"
  puts "Total laws: #{laws_data.count}"
  puts "Laws with materia tags: #{laws_data.count { |law| !law[:materias].empty? }}"
  puts "Laws without materia tags: #{laws_data.count { |law| law[:materias].empty? }}"
  
end

# Parse command line arguments
dry_run = ARGV.include?('--dry-run') || ARGV.include?('-d')

# Execute the export
export_laws_to_json(dry_run: dry_run)
