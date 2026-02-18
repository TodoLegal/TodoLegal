namespace :tags do
  desc "Generate JSON with document count per tag for given tag type(s). Usage: rake tags:document_count['materia,institucion']"
  task :document_count, [:tag_types] => :environment do |_task, args|
    if args[:tag_types].blank?
      puts "❌ Please provide at least one tag type name."
      puts "Usage: rake tags:document_count['materia']"
      puts "       rake tags:document_count['materia,institucion']"
      exit 1
    end

    tag_type_names = args[:tag_types].split(",").map(&:strip)
    results = []

    tag_type_names.each do |tag_type_name|
      tag_type = TagType.find_by(name: tag_type_name)

      if tag_type.nil?
        puts "Tag type '#{tag_type_name}' not found. Skipping..."
        next
      end

      puts "Processing tag type: #{tag_type_name} (ID: #{tag_type.id})"

      tags = Tag.where(tag_type_id: tag_type.id)
                .left_joins(:document_tags)
                .select("tags.id, tags.name, tags.tag_type_id, COUNT(document_tags.id) AS documents_count")
                .group("tags.id, tags.name, tags.tag_type_id")
                .order("documents_count DESC")

      tags.each do |tag|
        results << {
          tag_type: tag_type_name,
          tag_id: tag.id,
          tag_name: tag.name,
          documents_count: tag.documents_count.to_i
        }
      end

      puts "   Found #{tags.size} tags for '#{tag_type_name}'"
    end

    # Write JSON file
    output_path = Rails.root.join("tmp", "tags_document_count.json")
    File.write(output_path, JSON.pretty_generate(results))

    puts ""
    puts "✅ JSON generated at: #{output_path}"
    puts "   Total entries: #{results.size}"
  end
end
