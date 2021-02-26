class DocumentsController < ApplicationController
  before_action :set_document, only: [:show, :edit, :update, :destroy]
  before_action :authenticate_editor!, only: [:show, :new, :edit, :create, :update, :destroy]

  # GET /documents
  # GET /documents.json
  def index
    @documents = Document.all.order('publication_number DESC').page params[:page]
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
  end

  # GET /documents/1/edit
  def edit
  end

  # POST /documents
  # POST /documents.json
  def create
    @document = Document.new(document_params)
    respond_to do |format|
      if @document.save
        # download file
        require "google/cloud/storage"
        storage = Google::Cloud::Storage.new(project_id:"docs-tl", credentials: Rails.root.join("gcs.keyfile"))
        bucket = storage.bucket GCS_BUCKET
        file = bucket.file @document.original_file.key
        if params["document"]["process_gazette"] == "1"
          file.download "tmp/gazette.pdf"
          run_gazette_script @document, Rails.root.join("tmp") + "gazette.pdf"
          format.html { redirect_to gazette_path(@document.publication_number), notice: 'Document was successfully created.' }
        else
          format.html { redirect_to @document, notice: 'Document was successfully created.' }
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

  def getCleanDescription description
    description = description.truncate(400)
    while description.size > 0 and !(description[0] =~ /[A-Za-z]/)
      description[0] = ''
    end
    return description
  end

  def run_gazette_script document, document_pdf_path
    # run brazilian script
    puts "Starting python script"
    python_return_value = `python3 ~/GazetteSlicer/gazette.py #{ document_pdf_path } '#{ Rails.root.join("public", "gazettes") }' '#{document.id}'`
    puts "Starting pyton script"
    json_data = JSON.parse(python_return_value)
    first_element = json_data["files"].first
    # set original document values
    puts "Setting original document values"
    document.name = first_element["name"]
    document.description = getCleanDescription first_element["description"]
    document.publication_number = first_element["publication_number"]
    document.publication_date = first_element["publication_date"].to_date
    document.save
    tag = Tag.find_by_name(first_element["tag"])
    if tag
      DocumentTag.create(document_id: document.id, tag_id: tag.id)
    end
    first_element["institutions"].each do | institution |
      institution_tag = Tag.find_by_name(institution)
      if institution_tag
        DocumentTag.create(document_id: document.id, tag_id: institution_tag.id)
      end
    end
    document.url = document.generate_friendly_url
    document.save
    document.original_file.attach(
      io: File.open(
        Rails.root.join(
          "public",
          "gazettes",
          document.id.to_s, json_data["files"][0]["path"]).to_s
      ),
      filename: document.name + ".pdf"
    )
    # create the related documents
    puts "Creating related documents"
    json_data["files"].drop(1).each do |file|
      puts "Creating: " + file["name"]
      description = getCleanDescription file["description"]
      new_document = Document.create(
        name: file["name"],
        description: description,
        publication_number: document.publication_number,
        publication_date: document.publication_date)
      tag = Tag.find_by_name(file["tag"])
      if tag
        DocumentTag.create(document_id: new_document.id, tag_id: tag.id)
      end
      file["institutions"].each do |institution|
        institution_tag = Tag.find_by_name(institution)
        if institution_tag
          DocumentTag.create(document_id: new_document.id, tag_id: institution_tag.id)
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
        filename: document.name + ".pdf"
      )
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
      params.require(:document).permit(:name, :original_file, :url, :publication_date, :publication_number, :description)
    end
end
