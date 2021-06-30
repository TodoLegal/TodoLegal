IO.foreach('scripts/AlternativeNames/institutions') do |line|
  name = line.split(':', -1)[0]
  alternative_names = line.split(':', -1)[1]
  puts "==" + name + "=="
  tag = Tag.find_by_name(name)
  if !tag
    tag = Tag.create(name: name, tag_type_id: TagType.find_by_name("Institución").id)
  end
  AlternativeTagName.create(tag_id: tag.id, alternative_name: I18n.transliterate(name).downcase)
  alternative_names.split('|', -1).each do |alternative_name|
    alternative_name = alternative_name.strip
    puts alternative_name
    if !alternative_name.blank?
      AlternativeTagName.create(tag_id: tag.id, alternative_name: I18n.transliterate(alternative_name).downcase)
    end
  end
end