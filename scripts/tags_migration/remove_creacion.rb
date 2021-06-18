TagType.find_by_name("creacion").tags.each do |tag|
    puts tag.name
    tag.document_tags.destroy_all
    tag.law_tags.destroy_all
  end
  
  TagType.find_by_name("creacion").tags.destroy_all
  
  TagType.find_by_name("creacion").destroy