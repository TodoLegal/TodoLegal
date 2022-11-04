result = {}
TagType.where(name: "Tema").first.tags.each do |tag|
  result[tag.name] = tag.count
end
Hash[result.sort_by { |k,v| -v }].to_json
