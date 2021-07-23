Document.all.each do |document|
  if document.name != "Marcas de Fábrica" and document.name != "Avisos Legales" and document.name != "Gaceta"
    document.issue_id = document.name
    document.name = ""
    document.save
  end
end