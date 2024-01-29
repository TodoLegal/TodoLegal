marcas_type = DocumentType.find_by(name: "Marcas de Fábrica")
avisos_type = DocumentType.find_by(name: "Avisos Legales")
decreto_type = DocumentType.find_by(name: "Decreto")
acuerdo_type = DocumentType.find_by(name: "Acuerdo")
gaceta_type = DocumentType.find_by(name: "Gaceta")
otro_type = DocumentType.find_by(name: "Otro")
otros_counter = 0
otros_array = []

documents_with_no_document_type_id = Document.where(document_type_id: [nil, ""]).limit(500)

documents_with_no_document_type_id.all.each do | document |

  if !document.document_type_id
    if document.name == "Marcas de Fábrica"
      document.document_type_id = marcas_type.id
    elsif document.name == "Avisos Legales"
      document.document_type_id = avisos_type.id
    elsif document.name == "Gaceta"
      document.document_type_id = gaceta_type.id
    elsif document&.tags&.find_by_name("Acuerdo")
      document.document_type_id = acuerdo_type.id
    elsif document&.tags&.find_by_name("Decreto")
      document.document_type_id = decreto_type.id
    else
      document.document_type_id = otro_type.id
      otros_counter +=1
      otros_array.push(document.id)
    end
    document.save
  end
end

documents_to_publish = Document.where(publish: false).count
documents_to_publish = Document.where(publish: false).limit(500)
documents_to_publish.each do | document |
    document.publish = true
    document.save
end