class DocumentProcessingJob < ApplicationJob
queue_as :default
include ApplicationHelper
include DocumentsHelper

  def perform(document, document_pdf_path, user)
    puts ">slice_gazette called"
    json_data = run_slice_gazette_script(document, document_pdf_path, user)
    process_gazette document, document_pdf_path, user
    
    # Add nil check before using json_data["page_count"]
    if json_data && json_data["page_count"]
      document.start_page = 0
      document.end_page = json_data["page_count"] - 1
    else
      document.start_page = 0
      document.end_page = 0
      puts "Warning: Missing page_count in JSON data"
    end
    
    document.url = document.generate_friendly_url
    document.save
    
    # Add nil check before processing files
    if json_data && json_data["files"] && json_data["files"].any?
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
        #add materia tag
        if file["materia"].present?
          addTagIfExists(new_document.id, file["materia"])
        end
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
        puts "File uploaded"
      end
      
      if json_data["errors"] && json_data["errors"].any?
        json_data["errors"].each do |error|
          puts "Error found!"
          puts error.to_s
        end
      end
      
      puts "Created related documents"
      document_link = "https://todolegal.app/admin/gazettes/#{document.publication_number}"
      process_status = "success"
      if $discord_bot
        publication_number = document.publication_number
        discord_message = "Nueva gaceta seccionada en Valid! [#{publication_number}](https://todolegal.app/admin/gazettes/#{publication_number}) :scroll:"
        $discord_bot.send_message($discord_bot_document_upload, discord_message)
      end
    else
      puts "No files found in JSON data or empty files array"
      Rails.logger.error "No files found in JSON data or empty files array"
      document_link = "https://todolegal.app/admin/gazettes/#{document.publication_number}"
      process_status = "warning"
    end
    
    DocumentProcessingMailer.document_processing_complete(user, document_link, process_status).deliver
  end

  private

  def run_slice_gazette_script document, document_pdf_path, user
    puts ">run_slice_gazette_script called"
    python_return_value = `python3 ~/GazetteSlicer/slice_gazette.py #{ document_pdf_path } '#{ Rails.root.join("public", "gazettes") }' '#{document.id}'`
    document_link = "https://todolegal.app/documents/#{document.id}/edit"
    begin
      result = JSON.parse(python_return_value)
      # Ensure the result has the expected structure
      unless result.is_a?(Hash) && result["page_count"].is_a?(Integer) && result["files"].is_a?(Array)
        raise "Invalid JSON structure from slice_gazette.py"
      end
      return result
    rescue => e
      puts "Error in run_slice_gazette_script: #{e.message}"
      puts "Python output: #{python_return_value.inspect}"
      Rails.logger.error "Error in run_slice_gazette_script: #{e.message}"
      Rails.logger.error "Python output: #{python_return_value.inspect}"
      document.description = "Error: on slice gazette - #{e.message.truncate(200)}"
      document.save
      process_status = "error"
      DocumentProcessingMailer.document_processing_complete(user, document_link, process_status).deliver
      return { "page_count" => 0, "files" => [] }  # Return a default structure instead of empty hash
    end
  end

  def process_gazette document, document_pdf_path, user
    puts ">process_gazette called"
    python_return_value = `python3 ~/GazetteSlicer/process_gazette.py #{ document_pdf_path }`
    document_link = "https://todolegal.app/documents/#{document.id}/edit"
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