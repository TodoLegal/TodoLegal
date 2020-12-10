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
    related_documents = []
    DocumentRelationship.where(document_1_id: document.id).or(DocumentRelationship.where(document_2_id: document.id)).each do |document_relationship|
      if document_relationship.document_1_id == document.id
        related_documents.push({"document": Document.find_by_id(document_relationship.document_2_id), "relationship": document_relationship.relationship})
      else
        related_documents.push({"document": Document.find_by_id(document_relationship.document_1_id), "relationship": document_relationship.relationship})
      end
    end
    render json: {"document": document, "tags": document_tags, "related_documents": related_documents}
  end
  
  def get_documents
    if params["query"]
      documents = Document.all.search_by_all(params["query"]).limit(100)
    else
      documents = Document.all.limit(100)
    end
    if params["limit"]
      documents = documents.limit(params["limit"])
    end
    if params["offset"]
      documents = documents.offset(params["offset"])
    end
    render json: { "documents": documents }
  end
end
