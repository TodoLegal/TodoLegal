class Api::V1::DocumentsController < ApplicationController
  protect_from_forgery with: :null_session
  
  def get_document
    document = Document.find_by_id(params[:id])
    if !document
      render json: {"error": "Document not found."}
      return
    end
    document_group = []
    document_group.push({ "document": document, "relation": "belongs_to" })
    document_group.push({ "document": document, "relation": "is_sibling" })
    render json: {"document": document, "related_document": document_group}
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
