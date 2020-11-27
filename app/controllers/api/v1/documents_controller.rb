class Api::V1::DocumentsController < ApplicationController
  protect_from_forgery with: :null_session
  
  def get_dummy_document document_id
    document = {}
    document["id"] = document_id
    document["url"] = "https://todolegal.app/documents/1-ejemplo"
    document["title"] = "Delegacion director IDECOAS"
    document["publication_date"] = "2020-11-27T10:22:39.070+00:00"
    document["publication_number"] = "Acuerdo No. IDECOAS-006-2018"
    document["description"] = "Se delega para el periodo comprendido del dos (02) de mayo al once (11) de mayo del año dos mil diesiocho (2018) al abogado FREDY MAURICIO LAGOS para que asuma"
    document["file_url"] = "https://storage.googleapis.com/testground/b0kxth313i4h7yi1qahwqh0ise28?GoogleAccessId=testgoundsa%40quickstart-1587086905566.iam.gserviceaccount.com&Expires=1606472953&Signature=EhRHo93eE6qy%2F%2FhJyZnkQrwo7qRCV%2BBcX2RvzFHvCCM0G67N0MoKL3q%2B4AMk2iZu7W0vWriwemPOYD1UXYFcJdWAJdGYeVfG%2BEKHnNDPe49wr9qk%2FLoUv8cdg%2BKoU31qM%2BbfkPFrF%2BHy%2FwDDDAUQtwoQBZwi84k9zQbgFrQ3xXzOIvR7%2BpvEg9C7QS2ePx1VMktWD%2F8sWG26b8N5RreOF6QJ73DEbnz5NWpMZt8peRqUxtHCOPVZblCnq5cmAisLDgY3pGujtuPCQTvEQ4Ksb%2BxuWr2Lv%2BEJk%2FBQ1okW%2B10lQpjZLzqMlctsQ16EWeanyAQaBcMABezqPpbj6nup4g%3D%3D&response-content-disposition=inline%3B+filename%3D%222020-05-14+-+LG+-+35%252C252.pdf%22%3B+filename%2A%3DUTF-8%27%272020-05-14%2520-%2520LG%2520-%252035%252C252.pdf&response-content-type=application%2Fpdf"
    tags = []
    tags.push({ "name": "ambiental", "type": "materia" })
    tags.push({ "name": "Institucion de Desarrollo comunitario , agua y saneamiento", "type": "institucion" })
    document["tags"] = tags
    return document
  end
  
  def get_document
    #@document = Document.find_by_id(params[:id])
    document = get_dummy_document params[:id]
    document_group = []
    document_group.push({ "document": document, "relation": "belongs_to" })
    document_group.push({ "document": document, "relation": "is_sibling" })
    render json: {"document": document, "related_document": document_group}
  end
  
  def get_documents
    documents = []
    documents.push(get_dummy_document 1)
    documents.push(get_dummy_document 2)
    render json: {"documents": documents}
  end
end
