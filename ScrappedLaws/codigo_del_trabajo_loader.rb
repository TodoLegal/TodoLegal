require 'json'
file = File.read('ScrappedLaws/codigo_del_trabajo.json')
data_hash = JSON.parse(file)

for i in 0..data_hash["items"].size
  if data_hash["items"][i]["type"] == "articulo"
    number = data_hash["items"][i]["number"]
    body = data_hash["items"][i]["body"]
    Article.create(position: i, number: number, body: body, law_id: 3)
  end
  if data_hash["items"][i]["type"] == "capitulo"
    number = data_hash["items"][i]["number"]
    name = data_hash["items"][i]["name"]
    Chapter.create(position: i, number: number, name: name, law_id: 3)
  end
  if data_hash["items"][i]["type"] == "titulo"
    number = data_hash["items"][i]["number"]
    name = data_hash["items"][i]["name"]
    Title.create(position: i, number: number, name: name, law_id: 3)
  end
end