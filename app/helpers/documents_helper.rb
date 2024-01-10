module DocumentsHelper

  def check_document_duplicity(publication_number, document_type)
    # Check if a document with the same publication_number and document_type exists
    existing_document = Document.find_by(publication_number: publication_number, document_type: document_type)
  
    # Return true if a document already exists, false otherwise
    existing_document.present?
  end


  def delete_duplicated_document(publication_number, publication_date)
    document = Document.find_by(publication_number: publication_number, publication_date: publication_date)

    return false unless document
  
    if document.created_at >= 30.minutes.ago
      document.destroy
      puts "=============================================================================="
      puts "Documento eliminado aca"
      puts "=============================================================================="
      return true
    end
    false
  end

  def get_part_document_type_id name
    if name == "Avisos Legales"
      document_type = DocumentType.find_by_name("Avisos Legales")
      if document_type
        return document_type.id
      end
    elsif name == "Marcas de Fábrica"
      document_type = DocumentType.find_by_name("Marcas de Fábrica")
      if document_type
        return document_type.id
      end
    elsif name == "Gaceta"
      document_type = DocumentType.find_by_name("Gaceta")
      if document_type
        return document_type.id
      end
    elsif name == "Acuerdo" || name == "Decreto" || name == "Certificación"
      document_type = DocumentType.find_by_name("Sección de Gaceta")
      if document_type
        return document_type.id
      end
    elsif name == "Adedum"
      document_type = DocumentType.find_by_name("Ademdum")
      if document_type
        return document_type.id
      end
    elsif name == "Acta"
      document_type = DocumentType.find_by_name("Acta")
      if document_type
        return document_type.id
      end
    elsif name == "Auto Acordado"
      document_type = DocumentType.find_by_name("Auto Acordado")
      if document_type
        return document_type.id
      end
    elsif name == "Contrato"
      document_type = DocumentType.find_by_name("Contrato")
      if document_type
        return document_type.id
      end
    elsif name == "Convenio"
      document_type = DocumentType.find_by_name("Convenio")
      if document_type
        return document_type.id
      end
    elsif name == "Fe de Erratas"
      document_type = DocumentType.find_by_name("Fe de Erratas")
      if document_type
        return document_type.id
      end
    elsif name == "Licitación"
      document_type = DocumentType.find_by_name("Licitación")
      if document_type
        return document_type.id
      end
    elsif name == "Oficio"
      document_type = DocumentType.find_by_name("Oficio")
      if document_type
        return document_type.id
      end
    elsif name == "Reglamento"
      document_type = DocumentType.find_by_name("Reglamento")
      if document_type
        return document_type.id
      end
    elsif name == "Resolución"
      document_type = DocumentType.find_by_name("Resolución")
      if document_type
        return document_type.id
      end
    elsif name == "Tratado"
      document_type = DocumentType.find_by_name("Tratado")
      if document_type
        return document_type.id
      end
    else
      document_type = DocumentType.find_by_name("Otro")
    end
    return document_type
  end

  def delete_current_batch_files
    # Deletes files with TL stamp
    directory_path = '../GazetteSlicer/stamped_documents/'
    if Dir.exist?(directory_path)
      Dir.foreach(directory_path) do |file|
        next if file == '.' || file == '..'  # Skip current and parent directory references

        file_path = File.join(directory_path, file)
        File.delete(file_path)
        puts "File #{file_path} deleted successfully."
      end
    else
      puts "Directory #{directory_path} does not exist."
    end

    #Deletes downloaded files
    directory_path = '../GazetteSlicer/examples/batch-examples/'
    if Dir.exist?(directory_path)
      Dir.foreach(directory_path) do |file|
        next if file == '.' || file == '..'  # Skip current and parent directory references

        file_path = File.join(directory_path, file)
        File.delete(file_path)
        puts "File #{file_path} deleted successfully."
      end
    else
      puts "Directory #{directory_path} does not exist."
    end

  end
  
  def get_document_type auto_process_type
    if !auto_process_type
      return DocumentType.find_by_name("Ninguno").id
    elsif auto_process_type == "slice" or auto_process_type == "process"
      return get_gazette_document_type_id
    elsif auto_process_type == "judgement"
      return get_sentence_document_type_id
    elsif auto_process_type == "avisos"
      document_type = DocumentType.find_by_name("Avisos Legales")
      return document_type.id
    elsif auto_process_type == "marcas"
      document_type = DocumentType.find_by_name("Marcas de Fábrica")
      return document_type.id
    elsif auto_process_type == "autos"
      document_type = DocumentType.find_by_name("Auto Acordado")
      if document_type
        return document_type.id
      end
    elsif auto_process_type == "formats"
      document_type = DocumentType.find_by_name("Formato")
      if document_type
        return document_type.id
      end
    elsif auto_process_type == "comunicados"
      document_type = DocumentType.find_by_name("Comunicado")
      if document_type
        return document_type.id
      end
    elsif auto_process_type == "others"
      document_type = DocumentType.find_by_name("Otro")
      if document_type
        return document_type.id
      end
    else
      document_type = DocumentType.find_by_name("Sección de Gaceta")
      return document_type.id
    end
    return DocumentType.find_by_name("Ninguno").id
  end

end
