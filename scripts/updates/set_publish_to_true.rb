marcas_type = DocumentType.find_by(name: "Marcas de Fábrica")
avisos_type = DocumentType.find_by(name: "Aviso Legales")
decreto_type = DocumentType.find_by(name: "Decreto")
acuerdo_type = DocumentType.find_by(name: "Acuerdo")
gaceta_type = DocumentType.find_by(name: "Gaceta")
otro_type = DocumentType.find_by(name: "Otro")

documents_with_no_document_type_id = Document.where(document_type_id: [nil, ""]).limit(100)

documents_with_no_document_type_id.all.each do | document |

  if !document.document_type_id
    if document.name == "Marcas de Fábrica"
      document.document_type_id = marcas_type.id
    elsif document.name == "Avisos Legales"
      document.document_type_id = avisos_type.id
    elsif document.name == "Gaceta"
      document.document_type_id = gaceta_type.id
    elsif document.&tags&.find_by_name("Acuerdo")
      document.document_type_id = acuerdo_type.id
    elsif document&.tags&.find_b_name("Decreto")
      document.document_type_id = decreto_type.id
    else
      document.document_type_id = otro_type.id
    end
  end
end


Document.all.each do | document |
  if !document.publish
    document.publish = true
    document.save
  end
end