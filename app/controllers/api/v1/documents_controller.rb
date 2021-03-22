class Api::V1::DocumentsController < ApplicationController
  protect_from_forgery with: :null_session
  include ApplicationHelper
  
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

    user_document_visit_tracker = get_user_document_visit_tracker

    can_access = can_access_documents user_document_visit_tracker

    json_document = document.as_json
    if can_access and document.original_file.attached?
      json_document = json_document.merge(file: url_for(document.original_file))
    else
      json_document = json_document.merge(file: "")
    end
    render json: {"document": json_document,
      "tags": document_tags,
      "related_documents": related_documents,
      "visits": user_document_visit_tracker.visits,
      "can_access": can_access
    }
  end
  
  def get_documents
    limit = 100
    if !params["limit"].blank?
      limit = params["limit"]
    end
    query = "*"
    if !params["query"].blank?
      query = params["query"]
    end
    from = nil
    to = nil
    if !params["from"].blank?
      begin
        Date.parse(params["from"])
        from = params["from"]
      rescue ArgumentError
      end
    end
    if !params["to"].blank?
      begin
        Date.parse(params["to"])
        to = params["to"]
      rescue ArgumentError
      end
    end
    documents = Document.search(
      query,
      fields: [:name, :publication_number, :description],
      where:
      {
        publication_date: {gte: from, lte: to},
        name: {not: "Gaceta"},
      },
      limit: limit,
      offset: params["offset"].to_i,
      order: {publication_date: :desc})

    total_count = documents.total_count
    documents = documents.to_json
    documents = JSON.parse(documents)

    documents.each do | document |
      tags = []
      document_tags = DocumentTag.where(document_id: document["id"].to_i)
      if document_tags.first
        puts document_tags.first.tag.name
      end
      document_tags.each do |document_tag|
        if document_tag
          tags.push({"name": document_tag.tag.name, "type": document_tag.tag.tag_type.name})
        end
      end
      document["tags"] = tags
    end

    render json: { "documents": documents, "count": total_count }
  end
end
