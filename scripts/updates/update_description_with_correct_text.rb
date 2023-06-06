json_data = File.read('./scripts/tmp/texto_corregido.json')
data_hash = JSON.parse(json_data)

data_hash.each do | item |
  item_id = item['id']
  item_description = item['description']
  item_short_description = item['short_description']

  document = Document.find_by(id: item_id)

  if document
    document.update(description: item_description, short_description: item_short_description)
  else
    puts "no hay nada"
  end

end