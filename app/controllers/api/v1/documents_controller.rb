class Api::V1::DocumentsController < ApplicationController
  protect_from_forgery with: :null_session
  include ApplicationHelper
  before_action :document_exists!, only: [:get_document]
  before_action :doorkeeper_authorize!, only: [:get_document, :get_documents]
  skip_before_action :doorkeeper_authorize!, unless: :has_access_token?
  
  def get_document
    json_document = get_document_json
    can_access_document = true
    user = nil
    user_trial = nil
    if params[:access_token]
      user = User.find_by_id(doorkeeper_token.resource_owner_id)
    end

    can_access_document = can_access_documents(user)

    if user
      user_trial = UserTrial.find_by(user_id: user.id)
    end
    
    #get related documents
    related_documents = get_related_documents
    related_documents = related_documents.to_json
    related_documents = JSON.parse(related_documents)

    if can_access_document and @document.original_file.attached?
      json_document = json_document.merge(file: url_for(@document.original_file))
      related_documents = attach_file_to_documents(related_documents, true)
    else
      json_document = json_document.merge(file: "")
      related_documents = attach_file_to_documents(related_documents, false)
    end

    issuer_name = get_issuer_name @document.id

    render json: {"document": json_document,
      "issuer": issuer_name,
      "tags": get_document_tags,
      "related_documents": related_documents,
      "can_access": can_access_document,
      "downloads": user_trial ? user_trial.downloads : 0,
      "user_type": current_user_type_api(user),
    }
  end

  def get_documents
    user_id = 0
    if params[:access_token]
      user = User.find_by_id(doorkeeper_token.resource_owner_id)
      user_id = user.id
    end
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

    searchkick_where = {
      publication_date: {gte: from, lte: to},
      name: {not: "Gaceta"},
    }

    if !params["tags"].blank? and params["tags"].kind_of?(Array)
      document_ids = []
      params["tags"].each do |tag_name|
        tag = Tag.find_by_name(tag_name)
        tag_type = TagType.find_by(id: tag.tag_type_id)
        if tag
          document_ids = []
          if tag_type.name == "Institución"
            tag.issuer_document_tags.each do |issuer_tag|
              document_ids.push(issuer_tag.document_id)
            end 
          else
            tag.documents.each do |document|
              document_ids.push(document.id)
            end
          end
          document_ids = document_ids.uniq
        end
      end
      searchkick_where[:id] = {in: document_ids}
    end

    #if query is not empty returns result based in the boost level given to each field, else, returns results without boost and ordered by publication date
    if query != "*"
      documents = Document.search(
        query,
        fields: ["name^10", "issue_id^5", "short_description^2", "description"],
        where: searchkick_where,
        misspellings: {edit_distance: 2, below: 5},
        limit: limit,
        offset: params["offset"].to_i)
    else
      documents = Document.search(
        query,
        fields: ["name", "issue_id", "short_description", "description" ],
        where: searchkick_where,
        limit: limit,
        offset: params["offset"].to_i,
        order: {publication_date: :desc})
    end

    total_count = documents.total_count
    documents = documents.to_json
    documents = JSON.parse(documents)


    #Extract this into a reusable method
    can_access_document = true
    user = nil
    user_trial = nil
    if params[:access_token]
      user = User.find_by_id(doorkeeper_token.resource_owner_id)
    end

    if user
      user_trial = UserTrial.find_by(user_id: user.id)
    end

    can_access_document = can_access_documents(user)
    #this piece of code
    
    if can_access_document
      documents = attach_file_to_documents(documents, true)
    else
      documents = attach_file_to_documents(documents, false)
    end

    documents.each do | document |
      tags = []
      document_tags = DocumentTag.where(document_id: document["id"].to_i)
      if document_tags.first && document_tags.first.tag
        puts document_tags.first.tag.name
      end
      document_tags.each do |document_tag|
        if document_tag
          if document_tag.tag && document_tag.tag.tag_type
            tags.push({"name": document_tag.tag.name, "type": document_tag.tag.tag_type.name})
          elsif document_tag.tag
            tags.push({"name": document_tag.tag.name, "type": ""})
          end
        end
      end
      issuer_name = get_issuer_name document["id"].to_i
      document["issuer"] = issuer_name
      document["tags"] = tags
      document_json_post_process document["id"].to_i, document
    end

    if !params["query"].blank?
      $tracker.track(user_id, 'Valid Search', {
        'query' => query,
        'location' => "API",
        'limit' => limit,
        'offset' => params["offset"],
        'tags' => params["tags"],
        'results' => total_count
      })
    end

    render json: { "documents": documents, "count": total_count, "downloads": user_trial ? user_trial.downloads : 1, }
  end

protected
  def get_issuer_name document_id
    issuer = IssuerDocumentTag.find_by_document_id(document_id)
    if issuer && issuer.tag
      issuer_name = issuer.tag.name
    end
  end

  def get_document_json
    related_documents = Document.where(publication_number: @document.publication_number)
    json_document = @document.as_json
    return document_json_post_process @document.id, json_document
  end

  def document_json_post_process document_id, document_json
    judgement_auxiliary = JudgementAuxiliary.find_by_document_id(document_id)
    if judgement_auxiliary
      document_json["applicable_laws"] = judgement_auxiliary.applicable_laws
    end
    document_type = Document.find_by_id(document_id).document_type
    if document_type
      document_json["document_type"] = get_document_type_name(document_id, document_type)
    end
    document_json.delete("full_text")
    return document_json
  end

  def get_document_type_name document_id, document_type
    case document_type.name
    when "Sección de Gaceta"
      act_type_tag = TagType.find_by(name: "Tipo de Acto")
      type_name = Document.find_by_id(document_id).tags.find_by(tag_type_id: act_type_tag.id)
      type_name = type_name ? type_name.name : ""
      return type_name
    else
      return document_type.name
    end
    
  end

  def get_document_tags
    tags = []
    @document.tags.each do |tag|
      tags.push({"name": tag.name, "type": tag.tag_type.name})
    end
    return tags
  end

  def get_related_documents
    documents = nil
    if @document && @document&.document_type&.name == "Auto Acordado"
      #extract the year of the Auto Acordado date
      year_to_retrieve = @document.publication_date&.year
      #if year_to_retrieve if not nil, use that year, else use 2015
      year_to_retrieve = year_to_retrieve ? year_to_retrieve : 2015
      documents = Document.where("extract(year from publication_date) = ? AND document_type_id = ? AND id != ?", year_to_retrieve, @document.document_type_id, @document.id).limit(20)
    elsif @document & @document.publication_number == nil
      materia_type = TagType.find_by(name: "materia")
      document_tag = @document.tags.find_by(tag_type_id: materia_type.id)
      documents = Document.joins(:document_tags).where(document_tags: {tag_id: document_tag.id}).last(20)  
    else
      documents = Document.where(publication_number: @document.publication_number)
    end
  end

  def document_exists!
    @document = Document.find_by_id(params[:id])
    if !@document
      render json: {"error": "Document not found."}
      return
    end
  end

  def has_access_token?
    return params[:access_token]
  end

  def attach_file_to_documents documents, can_access
    docs = documents

    docs.each do | document |
      ar_document = Document.find_by_id(document["id"])
      if can_access && ar_document.original_file.attached?
        document["file"] = url_for(ar_document.original_file)
        document["can_access"] = true
      else
        document["file"] = ""
        document["can_access"] = false
      end
    end

    return docs
  end

end
