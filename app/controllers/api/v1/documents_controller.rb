class Api::V1::DocumentsController < ApplicationController
  protect_from_forgery with: :null_session
  
  def get_document
    document = Document.find_by_id(params[:id])
    if !document
      render json: {"error": "Document not found."}
      return
    end
    document_tags = []
    document.tags.each do |tag|
      document_tags.push({"name": tag.name, "type": tag.tag_type.name})
    end
    #related_documents = []
    #DocumentRelationship.where(document_1_id: document.id).or(DocumentRelationship.where(document_2_id: document.id)).each do |document_relationship|
    #  if document_relationship.document_1_id == document.id
    #    related_documents.push({"document": Document.find_by_id(document_relationship.document_2_id), "relationship": document_relationship.relationship})
    #  else
    #    related_documents.push({"document": Document.find_by_id(document_relationship.document_1_id), "relationship": document_relationship.relationship})
    #  end
    #end
    related_documents = Document.where(publication_number: document.publication_number)
    json_document = document.as_json
    if document.original_file.attached?
      json_document = json_document.merge(file: url_for(document.original_file))
    end
    render json: {"document": json_document, "tags": document_tags, "related_documents": related_documents}
  end
  
  def get_documents
    if params["query"]
      documents = Document.all.order('publication_date DESC').search_by_all(params["query"])
    else
      documents = Document.all.order('publication_date DESC')
    end
    if params["from"]
      documents = documents.where('publication_date >= ?', params["from"])
    end
    if params["to"]
      documents = documents.where('publication_date <= ?', params["to"])
    end
    documents = documents.limit(100)
    if params["limit"]
      documents = documents.limit(params["limit"])
    end
    if params["offset"]
      documents = documents.offset(params["offset"])
    end
    render json: { "documents": documents }
  end
end
