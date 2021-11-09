DocumentType.create(name: "Gaceta")
DocumentType.create(name: "Sección de Gaceta")
DocumentType.create(name: "Avisos Legales")
DocumentType.create(name: "Marcas de Fábrica")
DocumentType.create(name: "Sentencia")
DocumentType.create(name: "Ninguno")

Document.all.each do |d|
    if d.name == "Gaceta"
        puts "Added Gaceta"
        d.document_type_id = DocumentType.find_by_name("Gaceta").id.to_s
    elsif d.name == "Avisos Legales"
        puts "Added Avisos Legales"
        d.document_type_id = DocumentType.find_by_name("Avisos Legales").id.to_s
    elsif d.name == "Marcas de Fábrica"
        puts "Added Marcas de Fábrica"
        d.document_type_id = DocumentType.find_by_name("Marcas de Fábrica").id.to_s
    else
        puts "Added Sección de Gaceta"
        d.document_type_id = DocumentType.find_by_name("Sección de Gaceta").id.to_s
    end
    d.save
end