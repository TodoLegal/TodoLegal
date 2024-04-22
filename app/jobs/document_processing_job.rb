class DocumentProcessingJob < ApplicationJob
queue_as :default
include ApplicationHelper
include DocumentsHelper

  def perform(document, document_pdf_path, user)
    puts ">slice_gazette called"
    json_data = run_slice_gazette_script(document, document_pdf_path)
    process_gazette document, document_pdf_path
    document.start_page = 0
    document.end_page = json_data["page_count"] - 1
    document.url = document.generate_friendly_url
    document.save
    # set_content_disposition_attachment document.original_file.key, document.name + ".pdf"
    # create the related documents
    puts "Creating related documents"
    json_data["files"].each do |file|
      puts "Creating: " + file["name"]
      name = ""
      issue_id = ""
      short_description = ""
      long_description = ""
      if file["name"] == "Marcas de Fábrica"
        name = file["name"]
        short_description = "Esta es la sección de marcas de Fábrica de la Gaceta " + document.publication_number + " de fecha " + document.publication_date.to_s + "."
      elsif file["name"] == "Avisos Legales"
        name = file["name"]
        short_description = "Esta es la sección de avisos legales de la Gaceta " + document.publication_number + " de fecha " + document.publication_date.to_s + "."
      else
        issue_id = file["name"]
        short_description = cleanText(file["short_description"])
        long_description = cleanText(file["description"])
      end
      new_document = Document.create(
        name: name,
        issue_id: issue_id,
        publication_date: document.publication_date,
        publication_number: document.publication_number,
        short_description: short_description,
        description: long_description,
        full_text: cleanText(file["full_text"]),
        document_type_id: get_part_document_type_id(name),
        start_page: file["start_page"],
        end_page: file["end_page"],
        position: file["position"],
        publish: true
      )
      addTagIfExists(new_document.id, file["tag"])
      addIssuerTagIfExists(new_document.id, file["issuer"])
      addTagIfExists(new_document.id, "Gaceta")
      if file["name"] == "Marcas de Fábrica"
        addIssuerTagIfExists(new_document.id, "Varios")
        addTagIfExists(new_document.id, "Marcas")
        addTagIfExists(new_document.id, "Mercantil")
        addTagIfExists(new_document.id, "Propiedad Intelectual")
      elsif file["name"] == "Avisos Legales"
        addIssuerTagIfExists(new_document.id, "Varios")
        addTagIfExists(new_document.id, "Avisos Legales")
        addTagIfExists(new_document.id, "Licitaciones")
      end
      #adds institutions tags extracted by OCR
      file["institutions"].each do |institution|
        addTagIfExists(new_document.id, institution)
      end
      full_text_lower = file["full_text"].downcase
      
      #adds alternative name for institutions tags
      AlternativeTagName.all.each do |alternative_tag_name|
        if isWordInText alternative_tag_name.alternative_name, full_text_lower
          if !DocumentTag.exists?(document_id: new_document.id, tag_id: alternative_tag_name.tag_id)
            DocumentTag.create(document_id: new_document.id, tag_id: alternative_tag_name.tag_id)
          end
        end
      end
      new_document.url = new_document.generate_friendly_url
      new_document.save

      download_name = if issue_id.present?
                        issue_id
                      else name.present?
                        name
                      end

      puts "Uploading file"
      new_document.original_file.attach(
        io: File.open(
          Rails.root.join(
            "public",
            "gazettes",
            document.id.to_s, file["path"]).to_s
        ),
        filename: download_name + ".pdf",
        content_type: "application/pdf"
      )
      #set_content_disposition_attachment new_document.original_file.key, helpers.get_document_title(new_document) + ".pdf"
      puts "File uploaded"
    end
    json_data["errors"].each do |error|
      puts "Error found!"
      puts error.to_s
    end
    puts "Created related documents"
    document_link = "https://test.todolegal.app/admin/gazettes/#{document.publication_number}"
    process_status = "success"
    # if $discord_bot
    #   publication_number = @document.publication_number
    #   discord_message = "Nueva gaceta seccionada en Valid! [#{publication_number}](https://todolegal.app/admin/gazettes/#{publication_number}) :scroll:"
    #   $discord_bot.send_message($discord_bot_document_upload, discord_message)
    # end
    DocumentProcessingMailer.document_processing_complete(user, document_link, process_status).deliver
  end

  private

  def run_slice_gazette_script document, document_pdf_path
    puts ">run_slice_gazette_script called"
    python_return_value = `python3 ~/GazetteSlicer/slice_gazette.py #{ document_pdf_path } '#{ Rails.root.join("public", "gazettes") }' '#{document.id}'`
    begin
      result = JSON.parse(python_return_value)
      return result
    rescue
      document.description = "Error: on slice gazette"
      document.save
      process_status = "error"
      DocumentProcessingMailer.document_processing_complete(user, document_link, process_status).deliver
      return {}
    end
  end

  def process_gazette document, document_pdf_path
    puts ">process_gazette called"
    python_return_value = `python3 ~/GazetteSlicer/slice_gazette.py #{ document_pdf_path }`
    json_data = {}
    begin
      json_data = JSON.parse(python_return_value)
    rescue
      document.description = "Error: on process gazette"
      document.save
      process_status = "error"
      DocumentProcessingMailer.document_processing_complete(user, document_link, process_status).deliver
      return
    end
    document.name = "Gaceta"
    document.publication_number = json_data["gazette"]["number"]
    document.publication_date = json_data["gazette"]["date"]
    document.short_description = "Esta es la gaceta número " + document.publication_number + " de fecha " + document.publication_date.to_s + "."
    document.description = ""
    document.issue_id = json_data["gazette"]["number"]
    document.url = document.generate_friendly_url
    document.save
    addIssuerTagIfExists(document.id, "ENAG")
    addTagIfExists(document.id, "Gaceta")
  end

  def addIssuerTagIfExists(document_id, issuer_tag_name)
    if !issuer_tag_name.empty?
      tag = Tag.find_by_name(issuer_tag_name)
      if tag 
        IssuerDocumentTag.create(document_id: document_id, tag_id: tag.id)
      end
    end
  end

  def addTagIfExists document_id, tag_name
    if !tag_name.empty?
      tag = Tag.find_by_name(tag_name)
      if tag
        DocumentTag.create(document_id: document_id, tag_id: tag.id)
      end
    end
  end

  def cleanText text
    while text && !text.blank? and !(text[0] =~ /[A-Za-z]/)
      text[0] = ''
    end
    return text
  end

end