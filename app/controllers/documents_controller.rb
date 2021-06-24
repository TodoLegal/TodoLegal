class DocumentsController < ApplicationController
  before_action :set_document, only: [:show, :edit, :update, :destroy]
  before_action :authenticate_editor!, only: [:index, :show, :new, :edit, :create, :update, :destroy]

  # GET /documents
  # GET /documents.json
  def index
    @query = params["query"]
    if !@query.blank?
      if @query && @query.length == 5 && @query[1] != ','
        @query.insert(2, ",")
      end
      @documents = Document.where(publication_number: @query).order('publication_number DESC').page params[:page]
    else
      @documents = Document.all.order('publication_number DESC').page params[:page]
    end
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
    @comes_from_gazettes = params[:comes_from_gazette];
  end

  # GET /documents/1/edit
  def edit
    @document_type = @document.name
    @documents_count = Document.where(publication_number: @document.publication_number).count
    if @document.position
      @next_document = Document.where(publication_number: @document.publication_number).find_by(position: @document.position + 1 )
    end
    if @next_document
      @is_next_document_valid = true
    else
      @is_next_document_valid = false
    end

  end

  # POST /documents
  # POST /documents.json
  def create
    @document = Document.new(document_params)
    respond_to do |format|
      if @document.save
        # download file
        bucket = get_bucket
        file = bucket.file @document.original_file.key
        if params["document"]["auto_process_type"] == "slice"
          file.download "tmp/gazette.pdf"
          run_slice_gazette_script @document, Rails.root.join("tmp") + "gazette.pdf"
          if $discord_bot
            $discord_bot.send_message($discord_bot_channel_notifications, "Nueva gaceta seccionada en Valid! " + @document.publication_number + " :scroll:")
          end
          format.html { redirect_to gazette_path(@document.publication_number), notice: 'La gaceta se ha partido exitósamente.' }
        elsif params["document"]["auto_process_type"] == "process"
          file.download "tmp/gazette.pdf"
          run_process_gazette_script @document, Rails.root.join("tmp") + "gazette.pdf"
          if $discord_bot
            $discord_bot.send_message($discord_bot_channel_notifications, "Nueva gaceta en Valid! " + @document.publication_number + " :scroll:")
          end
          format.html { redirect_to edit_document_path(@document), notice: 'Se ha subido una gaceta.' }
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
        #if params[:original_file]
        #  run_gazette_script @document
        #end
        format.html { redirect_to @document, notice: 'Document was successfully updated.' }
        format.json { render :show, status: :ok, location: @document }
      else
        format.html { render :edit }
        format.json { render json: @document.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /documents/1
  # DELETE /documents/1.json
  def destroy
    @document.destroy
    respond_to do |format|
      format.html { redirect_to documents_url, notice: 'Document was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  def cleanText text
    while text.size > 0 and !(text[0] =~ /[A-Za-z]/)
      text[0] = ''
    end
    return text
  end

  def set_content_disposition_attachment key, file_name
    bucket = get_bucket
    file = bucket.file key
    file.update do |file|
      file.content_type = "application/pdf"
      file.content_disposition = "attachment; filename=" + file_name
    end
  end

  def run_process_gazette_script document, document_pdf_path
    # run slice script
    puts "Starting process python script"
    python_return_value = `python3 ~/GazetteSlicer/process_gazette.py #{ document_pdf_path }`
    puts "Starting process pyton script"
    json_data = JSON.parse(python_return_value)
    gazette_date = json_data["gazette"]["date"]
    gazette_number = json_data["gazette"]["number"]
    document.publication_date = gazette_date
    document.publication_number = gazette_number
    document.name = "Gaceta"
    document.save
  end

  def run_slice_gazette_script document, document_pdf_path
    # run slice script
    puts "Starting python script"
    python_return_value = `python3 ~/GazetteSlicer/slice_gazette.py #{ document_pdf_path } '#{ Rails.root.join("public", "gazettes") }' '#{document.id}'`
    puts "Starting pyton script"
    json_data = JSON.parse(python_return_value)
    run_process_gazette_script document, document_pdf_path
    document.url = document.generate_friendly_url
    document.save
    document.original_file.attach(
      io: File.open(
        Rails.root.join(
          "public",
          "gazettes",
          document.id.to_s, json_data["files"][0]["path"]).to_s
      ),
      filename: document.name + ".pdf",
      content_type: "application/pdf"
    )
    set_content_disposition_attachment document.original_file.key, document.name + ".pdf"
    # create the related documents
    puts "Creating related documents"
    json_data["files"].each do |file|
      puts "Creating: " + file["name"]
      new_document = Document.create(
        name: file["name"],
        publication_date: document.publication_date,
        publication_number: document.publication_number,
        description: cleanText(file["description"]),
        short_description: cleanText(file["short_description"]),
        full_text: cleanText(file["full_text"]),
        start_page: file["start_page"],
        end_page: file["end_page"],
        position: file["position"])
      tag = Tag.find_by_name(file["tag"])
      issuer = Tag.find_by_name(file["issuer"])
      if tag
        DocumentTag.create(document_id: new_document.id, tag_id: tag.id)
      end
      if issuer
        IssuerDocumentTag.create(document_id: new_document.id, tag_id: issuer.id)
      end
      file["institutions"].each do |institution|
        institution_tag = Tag.find_by_name(institution)
        if institution_tag
          DocumentTag.create(document_id: new_document.id, tag_id: institution_tag.id)
        end
      end
      full_text_lower = file["full_text"].downcase
      AlternativeTagName.each do |alternative_tag_name|
        if full_text.include? alternative_tag_name.alternative_name
          if !DocumentTag.exists?(document_id: new_document.id, tag_id: alternative_tag_name.tag_id)
            DocumentTag.create(document_id: new_document.id, tag_id: alternative_tag_name.tag_id)
          end
        end
      end
      new_document.url = new_document.generate_friendly_url
      new_document.save
      puts "Uploading file"
      new_document.original_file.attach(
        io: File.open(
          Rails.root.join(
            "public",
            "gazettes",
            document.id.to_s, file["path"]).to_s
        ),
        filename: document.name + ".pdf",
        content_type: "application/pdf"
      )
      set_content_disposition_attachment new_document.original_file.key, new_document.name + ".pdf"
      puts "File uploaded"
    end
    json_data["errors"].each do |error|
      puts "Error found!!!"
      puts error.to_s
    end
    puts "Created related documents"
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_document
      @document = Document.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def document_params
      params.require(:document).permit(:name, :original_file, :url, :publication_date, :publication_number, :description, :short_description)
    end

    def get_bucket
      require "google/cloud/storage"
      storage = Google::Cloud::Storage.new(project_id:"docs-tl", credentials: Rails.root.join("gcs.keyfile"))
      return storage.bucket GCS_BUCKET
    end
end
