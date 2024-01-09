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
  
    if document.created_at >= 2.hours.ago
      document.destroy
      puts "=============================================================================="
      puts "Documento eliminado aca"
      puts "=============================================================================="
      return true
    end

    false
  end
  

end
