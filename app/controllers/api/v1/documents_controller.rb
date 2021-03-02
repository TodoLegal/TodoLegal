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
      fields: [:name, :brand],
      where:
      {
        publication_date: {gte: from, lte: to}
      },
      limit: limit,
      offset: params["offset"].to_i,
      order: {publication_date: :desc})

    render json: { "documents": documents, "count": documents.total_count }
  end
end
