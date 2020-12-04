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
    document_group = []
    document_group.push({ "document": document, "relation": "belongs_to" })
    document_group.push({ "document": document, "relation": "is_sibling" })
    render json: {"document": document, "tags": document_tags, "related_document": document_group}
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

    document_tags = []
    document.tags.each do |tag|
      document_tags.push({"name": tag.name, "tags": document_tags,"type": tag.tag_type.name})
    end

    render json: { "documents": documents }
  end
end
