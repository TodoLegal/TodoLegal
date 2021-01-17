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
      json_document = json_document.merge(file: rails_blob_path(document.original_file, disposition: "attachment"))
    end
    fingerprint = (request.remote_ip +
      browser.to_s +
      browser.device.name +
      browser.device.id.to_s +
      browser.platform.name).hash.to_s
    user_document_visit_tracker = UserDocumentVisitTracker.find_by_fingerprint(fingerprint)
    if !user_document_visit_tracker
      user_document_visit_tracker = UserDocumentVisitTracker.create(fingerprint: fingerprint, visits: 0, period_start: DateTime.now)
    end
    user_document_visit_tracker.visits += 1
    if user_document_visit_tracker.period_start <= 1.minutes.ago # TODO set time window
      user_document_visit_tracker.period_start = DateTime.now
      user_document_visit_tracker.visits = 1
    end
    user_document_visit_tracker.save

    todo_visits = user_document_visit_tracker.visits
    todo_can_access = true
    if user_document_visit_tracker.visits > 3 # TODO set amount of visits
      todo_can_access = false
    end
    render json: {"document": json_document,
      "tags": document_tags,
      "related_documents": related_documents,
      "visits": todo_visits,
      "can_access": todo_can_access
    }
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

    documents_count = documents.count

    # limit and offset setup
    documents = documents.limit(100)
    if params["limit"]
      documents = documents.limit(params["limit"])
    end
    if params["offset"]
      documents = documents.offset(params["offset"])
    end
    render json: { "documents": documents, "count": documents_count }
  end
end
