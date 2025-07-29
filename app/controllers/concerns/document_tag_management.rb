module DocumentTagManagement
  extend ActiveSupport::Concern

  def addTagIfExists(document_id, tag_name)
    return if tag_name.blank?
    
    tag = Tag.find_by_name(tag_name)
    DocumentTag.create(document_id: document_id, tag_id: tag.id) if tag
  end

  def addIssuerTagIfExists(document_id, issuer_tag_name)
    return if issuer_tag_name.blank?
    
    tag = Tag.find_by_name(issuer_tag_name)
    IssuerDocumentTag.create(document_id: document_id, tag_id: tag.id) if tag
  end

  def cleanText(text)
    return "" if text.blank?
    
    while text && !text.blank? && !(text[0] =~ /[A-Za-z]/)
      text[0] = ''
    end
    text
  end

  def get_document_type_id_by_name(name)
    return get_empty_document_type_id if name.blank?
    
    # Normalize the document type name for lookup
    normalized_name = case name.downcase
                     when "acta"
                       "Acta"
                     when "acuerdo", "acuerdos"
                       "Acuerdo"
                     when "adendum"
                       "Adendum"
                     when "auto acordado", "autos acordados"
                       "Auto Acordado"
                     when "avance"
                       "Avance"
                     when "avisos legales"
                       "Avisos Legales"
                     when "certificación"
                       "Certificación"
                     when "circular CNBS", "circulares cnbs", "circular cnbs"
                       "Circular CNBS"
                     when "comunicado"
                       "Comunicado"
                     when "contrato", "contratos"
                       "Contrato"
                     when "convenio", "convenios"
                       "Convenio"
                     when "decreto", "decretos"
                       "Decreto"
                     when "fe de erratas"
                       "Fe de Erratas"
                     when "formato", "formatos"
                       "Formato"
                     when "gaceta"
                       "Gaceta"
                     when "ley", "leyes"
                       "Ley"
                     when "licitación", "licitaciones"
                       "Licitación"
                     when "marcas de fábrica"
                       "Marcas de Fábrica"
                     when "oficio", "oficios"
                       "Oficio"
                     when "otro"
                       "Otro"
                     when "reglamento", "reglamentos"
                       "Reglamento"
                     when "resolución", "resoluciones"
                       "Resolución"
                     when "sentencia", "sentencias"
                       "Sentencia"
                     when "tratado", "tratados"
                       "Tratado"
                     else
                       name.capitalize
                     end

    document_type = DocumentType.find_by_name(normalized_name)
    if document_type
      return document_type.id
    else
      Rails.logger.warn "Document type '#{name}' not found, using default"
      return get_empty_document_type_id
    end
  end

  def get_content_type(filename)
    extension = File.extname(filename).downcase
    case extension
    when '.pdf'
      'application/pdf'
    when '.doc'
      'application/msword'
    when '.docx'
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
    when '.txt'
      'text/plain'
    else
      'application/octet-stream'
    end
  end

  def get_part_document_type_id(name)
    # Delegate to the main method for consistency
    get_document_type_id_by_name(name)
  end

  private

  def get_empty_document_type_id
    # Try "Ninguno" first, then fall back to "Otro" for compatibility
    document_type = DocumentType.find_by_name("Otro")
    document_type&.id
  end
end
