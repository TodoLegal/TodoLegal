class DocumentsController < ApplicationController
  before_action :set_document, only: [:show, :edit, :update, :destroy]
  before_action :authenticate_editor!, only: [:index, :show, :new, :edit, :create, :update, :destroy]
  include DocumentsHelper
  include DocumentTagManagement

  # GET /documents
  # GET /documents.json
  def index
    @query = params["query"]
    @show_only_judgements = params["judgements"]
    @show_only_autos = params["autos"]
    @show_only_others = params["other"]
    @processed_documents = params["processed_documents"]
    @last_24_hours = params["last_hours"]
    #get batch statistics 
    batch_statistics = get_documents_batch_statistics
    @total_files = 0
    @total_pages = 0
    @total_time_seconds = 0
    @total_time_minutes = 0
    @average_pages_per_document = 0
    @average_time_per_document = 0
    @average_time_per_page = 0

    if batch_statistics

      @total_files = batch_statistics[:total_files]
      @total_pages = batch_statistics[:total_pages]
      @total_time_seconds = batch_statistics[:total_time_seconds]
      @total_time_minutes = batch_statistics[:total_time_minutes]
      @total_time_hours = @total_time_minutes/60

      @average_pages_per_document = @total_pages/@total_files
      @average_time_per_document = @total_time_seconds/@total_files
      @average_time_per_page = @total_time_seconds/@total_pages
      
      #numbers to just one decimal and add commas
      @total_time_seconds = @total_time_seconds.round(1)
      @total_time_minutes = @total_time_minutes.round(1)
      @total_time_hours = @total_time_hours.round(1)
      @average_pages_per_document = @average_pages_per_document.round(1)
      @average_time_per_document = @average_time_per_document.round(1)
      @average_time_per_page = @average_time_per_page.round(1)

      #convert to string with commas
      @total_files_string = ActionController::Base.helpers.number_with_delimiter(@total_files)
      @total_pages_string = ActionController::Base.helpers.number_with_delimiter(@total_pages)
      @total_time_seconds_string = ActionController::Base.helpers.number_with_delimiter(@total_time_seconds)
      @total_time_minutes_string = ActionController::Base.helpers.number_with_delimiter(@total_time_minutes)
      @total_time_hours_string = ActionController::Base.helpers.number_with_delimiter(@total_time_hours)
      @average_pages_per_document_string = ActionController::Base.helpers.number_with_delimiter(@average_pages_per_document)
      @average_time_per_document_string = ActionController::Base.helpers.number_with_delimiter(@average_time_per_document)
      @average_time_per_page_string = ActionController::Base.helpers.number_with_delimiter(@average_time_per_page)

    end

    if !@query.blank?
      if @query && @query.length == 5 && @query[1] != ','
        @query.insert(2, ",")
      end
      @documents = Document.where(publication_number: @query).order('publication_number DESC').page params[:page]
    else
      @documents = Document.order('created_at DESC')
                            .limit(50)
                            .page params[:page]
    end

    if @show_only_judgements
      @documents = Document.where(document_type_id: DocumentType.find_by_name("Sentencia")).order('publication_number DESC').page params[:page]
    end

    if @show_only_autos
      @documents = Document.where(document_type_id: DocumentType.find_by_name("Auto Acordado")).order('publication_date DESC').page params[:page]
    end

    if @show_only_others
      @documents = Document.where(document_type_id: DocumentType.find_by_name("Otro")).order('publication_date DESC').page params[:page]
    end

    if params[:last_documents]
      limit = params[:last_documents].to_i
      last_documents = Document.order('created_at DESC').limit(limit)
      @documents = Kaminari.paginate_array(last_documents).page(params[:page])
    end

    if @last_24_hours.present?
      last_documents = Document.where("created_at >= ?", 24.hours.ago).order('created_at DESC')
      @documents = Kaminari.paginate_array(last_documents).page(params[:page])
    end

    expires_in 10.minutes
  end

  # GET /documents/1
  # GET /documents/1.json
  def show
    if @document.publication_number
      @documents_in_same_gazette =
        Document.where(publication_number: @document.publication_number)
        .where.not(id: @document.id)
    end
  end

  # GET /documents/new
  def new
    @document = Document.new
    @selected_document_type = params[:selected_document_type]
    @comes_from_gazettes = params[:comes_from_gazette]
  end

  # GET /documents/1/edit
  def edit
    @document_type = nil
    @redirect_url = params["return_to"]
    session[:redirect_url] = @redirect_url if @redirect_url

    if @document.document_type
      @document_type = @document.document_type.name
    end
    @documents_count = Document.where(publication_number: @document.publication_number).where.not(position: nil).count
    if @document.position
      @next_document = get_next_document @document
      @previous_document = Document.where(publication_number: @document.publication_number).find_by(position: @document.position - 1 )
    end
    if @next_document
      @is_next_document_valid = true
    else
      @is_next_document_valid = false
    end

    if @previous_document
      @is_previous_document_valid = true
    else
      @is_previous_document_valid = false
    end

  end

  # POST /documents
  # POST /documents.json
  def create
    @document = Document.new(document_params)
    @document.document_type_id = get_document_type(params["document"]["auto_process_type"])
    respond_to do |format|
      if @document.save

        #add user that uploaded the document
        if current_user
          @document.uploaded_by = current_user.first_name + " " + current_user.last_name
          @document.save
        end

        # download file
        bucket = get_bucket
        file = bucket.file @document.original_file.key
        if params["document"]["auto_process_type"] == "slice"
          get_gazette_document_type_id #this is maybe a misplaced and useless call to this method, delete later?
          file.download "tmp/gazette.pdf"
          document_pdf_path = (Rails.root.join("tmp") + "gazette.pdf").to_s
          DocumentProcessingJob.perform_later(@document, document_pdf_path, current_user)

          format.html { redirect_to documents_path, notice: 'El documento esta siendo procesado. Se te enviará un correo y una notificación de discord cuando esté listo.' }
        elsif params["document"]["auto_process_type"] == "process"
          file.download "tmp/gazette.pdf"
          process_gazette @document, Rails.root.join("tmp") + "gazette.pdf"
          if $discord_bot
            publication_number = ""
            publication_number = @document.publication_number if @document.publication_number
            $discord_bot.send_message($discord_bot_document_upload, "Nueva gaceta en Valid! " + publication_number + " :scroll:")
          end
          format.html { redirect_to edit_document_path(@document), notice: 'Se ha subido una gaceta.' }
        elsif params["document"]["auto_process_type"] == "judgement"
          JudgementAuxiliary.create(document_id: @document.id, applicable_laws: "")
          format.html { redirect_to edit_document_path(@document), notice: 'Se ha subido una sentencia.' }
        elsif params["document"]["auto_process_type"] == "seccion"
          bucket = get_bucket
          file = bucket.file @document.original_file.key
          file.download "tmp/seccion_de_gaceta.pdf"
          add_stamp_to_unprocessed_document @document, Rails.root.join("tmp") + "seccion_de_gaceta.pdf"
          extract_text_from_document @document, Rails.root.join("tmp") + "seccion_de_gaceta.pdf", "slice"
          if $discord_bot
            document_id = @document.id
            discord_message = "Nueva sección de gaceta subida en Valid! [#{document_id}](https://todolegal.app/documents/#{document_id}) :scroll:"
            $discord_bot.send_message($discord_bot_document_upload, discord_message)
          end
          format.html { redirect_to edit_document_path(@document), notice: 'Se han subido Avisos Legales.' }
        elsif params["document"]["auto_process_type"] == "avisos"
          bucket = get_bucket
          file = bucket.file @document.original_file.key
          file.download "tmp/avisos_legales.pdf"
          add_stamp_to_unprocessed_document @document, Rails.root.join("tmp") + "avisos_legales.pdf"
          extract_text_from_document Rails.root.join("tmp") + "avisos_legales.pdf", "Avisos Legales"
          if $discord_bot
            $discord_bot.send_message($discord_bot_document_upload, "Nuevos avisos legales subidos en Valid! :scroll:")
          end
          format.html { redirect_to edit_document_path(@document), notice: 'Se han subido Avisos Legales.' }
        elsif params["document"]["auto_process_type"] == "marcas"
          bucket = get_bucket
          file = bucket.file @document.original_file.key
          file.download "tmp/marcas.pdf"
          add_stamp_to_unprocessed_document @document, Rails.root.join("tmp") + "marcas.pdf"
          extract_text_from_document @document, Rails.root.join("tmp") + "marcas.pdf", "Marcas de Fábrica"
          if $discord_bot
            $discord_bot.send_message($discord_bot_document_upload, "Nuevas Marcas de Fábrica subidas en Valid! :scroll:")
          end
          format.html { redirect_to edit_document_path(@document), notice: 'Se han subido Marcas de Fábrica.' }
        elsif params["document"]["auto_process_type"] == "autos"
          bucket = get_bucket
          file = bucket.file @document.original_file.key
          file.download "tmp/auto_acordado.pdf"
          slice_autos_acordados @document, Rails.root.join("tmp") + "auto_acordado.pdf"
          if $discord_bot
            $discord_bot.send_message($discord_bot_document_upload, "Nuevos autos acordados seccionados en Valid! :scroll:")
          end
          format.html { redirect_to documents_path+"?autos=true", notice: 'Autos acordados se han partido exitosamente.' }
        elsif params["document"]["auto_process_type"] == "formats"
          bucket = get_bucket
          file = bucket.file @document.original_file.key
          file.download "tmp/formato.pdf"
          add_stamp_to_unprocessed_document @document, Rails.root.join("tmp") + "formato.pdf"
          if $discord_bot
            $discord_bot.send_message($discord_bot_document_upload, "Nuevo formato subido a Valid! :scroll:")
          end
          format.html { redirect_to edit_document_path(@document), notice: 'Se ha subido un nuevo formato.' }
        elsif params["document"]["auto_process_type"] == "comunicados"
          bucket = get_bucket
          file = bucket.file @document.original_file.key
          file.download "tmp/comunicado.pdf"
          add_stamp_to_unprocessed_document @document, Rails.root.join("tmp") + "comunicado.pdf"
          if $discord_bot
            $discord_bot.send_message($discord_bot_document_upload, "Nuevo comunicado subido a Valid! :scroll:")
          end
          format.html { redirect_to edit_document_path(@document), notice: 'Se ha subido un nuevo comunicado.' }
        elsif params["document"]["auto_process_type"] == "cnbs"
          bucket = get_bucket
          file = bucket.file @document.original_file.key
          file.download "tmp/circular_cnbs.pdf"
          add_stamp_to_unprocessed_document @document, Rails.root.join("tmp") + "circular_cnbs.pdf"
          extract_text_from_document @document, Rails.root.join("tmp") + "circular_cnbs.pdf", "Circular CNBS"
          if $discord_bot
            document_id = @document.id
            discord_message = "Nueva circular de la CNBS subida en Valid! [#{document_id}](https://todolegal.app/documents/#{document_id}) :scroll:"
            $discord_bot.send_message($discord_bot_document_upload, discord_message)
          end
          format.html { redirect_to edit_document_path(@document), notice: 'Se han subido Avisos Legales.' }
        elsif params["document"]["auto_process_type"] == "others"
          bucket = get_bucket
          file = bucket.file @document.original_file.key
          file.download "tmp/documento.pdf"
          add_stamp_to_unprocessed_document @document, Rails.root.join("tmp") + "documento.pdf"
          extract_text_from_document @document, Rails.root.join("tmp") + "documento.pdf", "Otro"
          format.html { redirect_to edit_document_path(@document), notice: 'Se ha subido un documento.' }
          if $discord_bot
            $discord_bot.send_message($discord_bot_document_upload, "Nuevo documento subido a Valid! :scroll:")
          end
        else
          format.html { redirect_to edit_document_path(@document), notice: 'Se ha subido un documento.' }
        end
      else
        format.html { render :new }
        format.json { render json: @document.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /documents/1
  # PATCH/PUT /documents/1.json
  def update
    respond_to do |format|
      if @document.update(document_params)

        #add stamp to document if it has been updated
        if params[:document].key?("original_file")
          bucket = get_bucket
          file = bucket.file @document.original_file.key
          file.download "tmp/documento.pdf"
          add_stamp_to_unprocessed_document @document, Rails.root.join("tmp") + "documento.pdf"
        end
        
        if !params[:document]["applicable_laws"].blank?
          judgement_auxiliary = JudgementAuxiliary.find_by_document_id(@document.id)
          if judgement_auxiliary
            judgement_auxiliary.applicable_laws = params[:document]["applicable_laws"]
            judgement_auxiliary.save
          end
        end
        if params[:commit] == 'Guardar cambios'
          @document.publish = true
          @document.save
          add_name_to_document(@document)
          #redirect to provided url if exists
          if session[:redirect_url]
            format.html { redirect_to edit_document_path(@document, return_to: session[:redirect_url]), notice: 'Document was successfully updated.' }
          else
            format.html { redirect_to edit_document_path(@document), notice: 'Document was successfully updated.' }
          end
          flash.now[:notice] = 'Cambios guardados'
          format.turbo_stream do
            render turbo_stream: turbo_stream.replace(
              "autosave_flash_document", 
              partial: "layouts/flash", 
              locals: {
                alert_origin: "document",
                alert_type: "success",
                fade_timeout: "0"
              }
            )
          end
        elsif params[:commit] == 'Guardar y siguiente'
          add_name_to_document(@document)
          @document.publish = true
          @document.save
          format.html { redirect_to edit_document_path(get_next_document @document), notice: 'Document was successfully updated.' }
        elsif params[:commit] == 'Guardar y regresar a PIIL'
          add_name_to_document(@document)
          @document.publish = true
          @document.save
          #redirect to provided url
          format.html { redirect_to session[:redirect_url], allow_other_host: true, notice: 'Document was successfully updated.' }
        elsif params[:commit] == 'Subir nueva sentencia'
          format.html { redirect_to new_document_path + "?selected_document_type=judgement" }
        else
          # if neither of the above conditions are met, then the autosave is being called
          flash.now[:notice] = 'Cambios guardados automaticamente'
          format.turbo_stream do
            render turbo_stream: turbo_stream.replace(
              "autosave_flash_document", 
              partial: "layouts/flash", 
              locals: {
                alert_origin: "document",
                alert_type: "success",
                fade_timeout: "2000"
              }
            )
          end
          format.html { redirect_to edit_document_path(@document), notice: 'Document was successfully updated.' }
          format.json { render :show, status: :ok, location: @document }
        end
      else
        flash.now[:alert] = "There was an error updating the document."
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "autosave_flash_document", 
            partial: "layouts/flash", 
            locals: {
              alert_origin: "document",
              alert_type: "danger",
              fade_timeout: "0"
            }
          )
        end
        format.html { render :edit }
        format.json { render json: @document.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /documents/1
  # DELETE /documents/1.json
  def destroy
    comes_from_gazette = params[:gazette]

    @document.destroy
    respond_to do |format|
      if comes_from_gazette.present?
        format.html { redirect_to gazette_path(@document.publication_number), notice: 'Document was successfully destroyed.' }
      else
        format.html { redirect_to documents_url, notice: 'Document was successfully destroyed.' }
      end
      format.json { head :no_content }
    end
  end

  def cleanText text
    while text && !text.blank? and !(text[0] =~ /[A-Za-z]/)
      text[0] = ''
    end
    return text
  end

  def clean_autos_issue_id text
    text = text.gsub("no", "No")
    text = text.gsub("actas", "Acta")
    text = text.gsub("scsj", "SCSJ")
    text = text.gsub("pcsj", "PCSJ")
    text = text.gsub("dpcsj","DPCSJ")
    text = text.gsub("dPCSJ","DPCSJ")
    text = text.gsub("dapj","DAPJ")
    text = text.gsub("numero", "No.")
    text = text.gsub("ssc", "SSC")
    text = text.gsub("scjycj", "SCJYCJ")
    text = text.gsub("cjycj", "CJYCJ")
    text = text.gsub("scsjycj", "SCSJYCJ")
    text = text.gsub("0i", "01")
    text = text.gsub("pecsj", "PECSJ")
    text = text.gsub(/[, -]+$/, '')
    return text
  end

  def add_stamp_to_unprocessed_document document, document_pdf_path
    document_name = `python3 ~/GazetteSlicer/add_stamp_to_document.py #{ document_pdf_path } '#{ Rails.root.join("public", "documents") }'`
    document_name = JSON.parse(document_name)
    document.original_file.attach(
      io: File.open(
        Rails.root.join(
          "public",
          "documents",
          document_name).to_s
      ),
      filename: document_name,
      content_type: "application/pdf"
    )
  end

  def extract_text_from_document(document, document_pdf_path, document_type)
    # Extract text from the PDF
    extracted_text = `python3 ~/GazetteSlicer/src/data_processing/process_single_document.py #{ document_pdf_path } #{ document_type }`
    
    begin
      # Parse the JSON string to get the result
      result = JSON.parse(extracted_text)
      
      # Update the document with the extracted information
      document.full_text = result["full_text"] if result["full_text"].present?
      document.description = result["description"] if result["description"].present?
      document.short_description = result["short_description"] if result["short_description"].present?
      
      # Add materia tag if present
      if result["materia"].present?
        addTagIfExists(document.id, result["materia"]) if result["materia"].present?
      end
      
      # Save the document
      document.save
      return true
    rescue JSON::ParserError => e
      Rails.logger.error "Failed to parse JSON from extract_text_from_document: #{e.message}"
      Rails.logger.error "Raw output: #{extracted_text.inspect}"
      
      # Set error message in document
      document.description = "Error: Failed to parse text from document"
      document.save
      return false
    end
  end

  def add_name_to_document(document)
    # Download the file
    bucket = get_bucket
    file = bucket.file(document.original_file.key)
    download_path = Rails.root.join("tmp", "documento.pdf")
    file.download(download_path.to_s)
  
    # Construct the new document name
    issue_id = document.issue_id || document.id
    issuer_document_tag = document.issuer_document_tags&.first&.tag&.name
    new_document_name = "TodoLegal-#{issue_id}"
    new_document_name += "-#{issuer_document_tag}" if issuer_document_tag.present?
    new_document_name += ".pdf"
  
    # Rename the file
    old_path = download_path.to_s
    new_path = Rails.root.join("tmp", new_document_name).to_s
    File.rename(old_path, new_path)
  
    # Attach the renamed file to the document
    document.original_file.attach(
      io: File.open(new_path),
      filename: new_document_name,
      content_type: "application/pdf"
    )
  end

  #Process full gazette without slicing
  def process_gazette document, document_pdf_path
    puts ">process_gazette called"
    python_return_value = `python3 ~/GazetteSlicer/process_gazette.py #{ document_pdf_path }`
    json_data = {}
    begin
      json_data = JSON.parse(python_return_value)
    rescue
      document.description = "Error: on process gazette"
      document.save
      return
    end
    document.name = "Gaceta"
    document.publication_number = json_data["gazette"]["number"]
    document.publication_date = json_data["gazette"]["date"]
    document.short_description = "Esta es la gaceta número " + document.publication_number + " de fecha " + document.publication_date.to_s + "."
    document.description = ""
    document.issue_id = json_data["gazette"]["number"]
    document.url = document.generate_friendly_url
    document.publish = true
    document.save
    addIssuerTagIfExists(document.id, "ENAG")
    addTagIfExists(document.id, "Gaceta")
  end

  #Autos acordados scripts
  def run_slice_autos_acordados_script document, document_pdf_path
    puts ">run_slice_autos_acordados_script called"
    python_return_value = `python3 ~/GazetteSlicer/slice_autos_acordados.py #{ document_pdf_path } '#{ Rails.root.join("public", "autos_acordados") }' '#{document.id}'`
    begin
      result = JSON.parse(python_return_value)
      return result
    rescue
      document.description = "Error: on slice autos acordados"
      document.save
      return {}
    end
  end
 
  def slice_autos_acordados document, document_pdf_path
    puts "slice_autos_acordados called"
    json_data = run_slice_autos_acordados_script(document, document_pdf_path)
    # document.url = document.generate_friendly_url
    document.save

    puts "Creating autos acordados"

    json_data["files"].each do | file |
      puts "creating auto acordado " + file["internal_id"]
      name = ""
      tema = file["tag_tema"]
      alt_issue_id = file["alt_issue_id"]
      materias = file["materias"]
      alt_issue_id = clean_autos_issue_id(alt_issue_id)

      if alt_issue_id != ""
        alt_issue_id = alt_issue_id[0].upcase + alt_issue_id[1..]
        name = alt_issue_id
      end

      if tema != ""
        tema = tema[0] + tema[1..].downcase
        if name != ""
          name = name + " " + tema
        else
          name = tema
        end
      end

      if name == ""
        name = "Auto Acordado " + file["issue_id"]
      end

      document_type =  DocumentType.find_by_name("Auto Acordado")
      new_document = Document.create(
        name: name,
        issue_id: file["issue_id"],
        publication_date: file["publication_date"],
        short_description: file["short_description"],
        description: file["description"],
        full_text: cleanText(file["full_text"]),
        document_type_id: document_type.id,
        alternative_issue_id: alt_issue_id,
        internal_id:  file["internal_id"],
        publish: true
      )

      #tags section
      addIssuerTagIfExists(new_document.id, "Poder Judicial")
      addTagIfExists(new_document.id, "Justicia")

      if alt_issue_id.include?("Oficio") || alt_issue_id.include?("oficio")
        addTagIfExists(new_document.id, "Oficio")
      else
        addTagIfExists(new_document.id, "Circular")
      end

      if alt_issue_id.include?("Resolución") || alt_issue_id.include?("resolución")
        addTagIfExists(new_document.id, "Resolución")
      end

      if materias != []
        addTagIfExists(new_document.id, materias[0])
      end

      #adds tema tags extracted by OCR
      file["temas"].each do |tema|
        addTagIfExists(new_document.id, tema)
      end

      puts "Uploading file"
      new_document.original_file.attach(
        io: File.open(
          Rails.root.join(
            "public",
            "autos_acordados",
            document.id.to_s, file["internal_id"] + ".pdf").to_s
        ),
        filename: file["internal_id"] + ".pdf",
        content_type: "application/pdf"
      )
      puts "File uploaded"

    end
    puts "Created related documents"
  end

  def process_documents_batch

    #Extract the files data from the generated json
    json_data = File.read('processed_files.json')
    json_data = JSON.parse(json_data)

    document_count = 0
    puts "Creating related documents"
    json_data["files"].each do |file|
      puts "Creating: " + file["name"]
      name = file["name"]
      issue_id = file["issue_id"]
      publication_number = file["publication_number"]
      publication_date = file["publication_date"]
      document_type = file["document_type"]
      short_description = ""
      long_description = ""
      publish = false

      #check if document already in data base
      if check_document_duplicity(publication_number, document_type, issue_id)
        puts "Document already exists. Skipping..."
        next  # Skip the rest of the loop and move to the next iteration
      end
      
      #Check if document exists, if documents exists and is from 2021 backwards, delete it
      date_string = publication_date
      date = DateTime.parse(date_string)
      year = date.year
      document_deleted = delete_duplicated_document(publication_number, date) if year <= 2019
      if document_deleted
        Rails.logger.info("==============================================================================")
        Rails.logger.info("Documento eliminado")
        Rails.logger.info("==============================================================================")
      end

      if document_type == "Marcas de Fábrica"
        short_description = "Esta es la sección de Marcas de Fábrica de la Gaceta " + publication_number + " de fecha " + publication_date + "."
        publish = true
      elsif document_type == "Avisos Legales"
        short_description = "Esta es la sección de avisos legales de la Gaceta " + publication_number + " de fecha " + publication_date + "."
        publish = true
      elsif document_type== "Gaceta"
        short_description = "Esta es la gaceta número " + publication_number + " de fecha " + publication_date + "."
        publish = true
      else
        short_description = cleanText(file["short_description"])
        long_description = cleanText(file["description"])
      end

      new_document = Document.create(
        name: name,
        issue_id: issue_id,
        publication_date: publication_date,
        publication_number: publication_number,
        short_description: short_description,
        description: long_description,
        full_text: cleanText(file["full_text"]),
        document_type_id: get_part_document_type_id(document_type),
        publish: publish
      )

      addTagIfExists(new_document.id, file["tag"])
      addIssuerTagIfExists(new_document.id, file["issuer"])
      addTagIfExists(new_document.id, "Gaceta")

      if file["materia"].present?
        addTagIfExists(new_document.id, file["materia"])
      end

      if document_type == "Marcas de Fábrica"
        addIssuerTagIfExists(new_document.id, "Varios")
        addTagIfExists(new_document.id, "Marcas")
        addTagIfExists(new_document.id, "Mercantil")
        addTagIfExists(new_document.id, "Propiedad Intelectual")
      elsif document_type == "Avisos Legales"
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
      document_count += 1

      download_name = if issue_id.present?
                        issue_id
                      elsif name.present?
                        name
                      else
                        document_type
                      end

      #add user that uploaded the document
      if current_user
        new_document.uploaded_by = current_user.first_name + " " + current_user.last_name
        new_document.save
      end

      puts "Uploading file"
      # base_path = Rails.root.join('..', 'GazetteSlicer', 'stamped_documents')
      # file_path = File.join(base_path, file['path'])
      new_document.original_file.attach(
        io: File.open(file['path']),
        filename: "#{download_name}.pdf",
        content_type: 'application/pdf'
      )
    end

    #delete local files after uploading them
    delete_current_batch_files

    redirect_to documents_path(last_documents: document_count, processed_documents: document_count), notice: "Batch processed successfully. #{document_count} documents uploaded."
  end

  def process_cnbs_batch
    processor = DocumentJsonBatchProcessor.new(current_user)
    result = processor.process('processed_cnbs_files.json')
    
    Rails.logger.info "Batch processing completed. #{result.summary}"
    
    if result.errors.any?
      Rails.logger.error "Batch processing errors: #{result.errors.join('; ')}"
    end
    
    redirect_to documents_path(
      last_documents: result.success_count, 
      processed_documents: result.success_count
    ), notice: "JSON batch processed successfully. #{result.summary}"
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_document
      @document = Document.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def document_params
      params.require(:document).permit(:issue_id, :alternative_issue_id, :name, :original_file, :url, :publication_date, :publication_number, :description, :short_description, :status, :hierarchy, :document_type_id, :publish)
    end

    def get_bucket
      require "google/cloud/storage"
      storage = Google::Cloud::Storage.new(project_id:"docs-tl", credentials: Rails.root.join("gcs.keyfile"))
      return storage.bucket GCS_BUCKET
    end

    def get_next_document document
      Document.where(publication_number: document.publication_number).find_by(position: document.position + 1 )
    end

    def get_empty_document_type_id
      document_type = DocumentType.find_by_name("Ninguno")
      if document_type
        return document_type.id
      end
      return nil
    end

    def get_gazette_document_type_id
      document_type = DocumentType.find_by_name("Gaceta")
      if document_type
        return document_type.id
      end
      return nil
    end

    def get_sentence_document_type_id
      document_type = DocumentType.find_by_name("Sentencia")
      if document_type
        return document_type.id
      end
      return nil
    end

end
