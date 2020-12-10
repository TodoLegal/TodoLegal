class DocumentsController < ApplicationController
  before_action :set_document, only: [:show, :edit, :update, :destroy]

  # GET /documents
  # GET /documents.json
  def index
    @documents = Document.all
  end

  # GET /documents/1
  # GET /documents/1.json
  def show
    @json_data = {}
    @json_data["files"] = []
    if File.exist?("gazettes/" + @document.id.to_s + "/data.json")
      file = File.read(Rails.root.join("public", "gazettes",@document.id.to_s,"data.json").to_s)
      @json_data = JSON.parse(file)
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
        run_gazette_script @document.id
        format.html { redirect_to @document, notice: 'Document was successfully created.' }
        format.json { render :show, status: :created, location: @document }
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
        if params[:original_file]
          run_gazette_script @document.id
        end
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

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_document
      @document = Document.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def document_params
      params.require(:document).permit(:name, :original_file, :url, :publication_date, :publication_number, :description)
    end

    def run_gazette_script document_id
      # download file
      require "google/cloud/storage"
      storage = Google::Cloud::Storage.new(project_id:"testground", credentials: Rails.root.join("gcs.keyfile"))
      bucket = storage.bucket "testground"
      file = bucket.file @document.original_file.key
      file.download "tmp/gazette.pdf"
      # run brazilian script
      python_return_value = `python3 ~/GazetteSlicer/gazette.py tmp/gazette.pdf '#{ Rails.root.join("public", "gazettes") }' '#{document_id}'`
      output = JSON.parse(python_return_value)
      json_data = JSON.parse(File.read(output[0]))
      json_data["files"].each do |file|
        puts "name:" + file["name"]
        puts "path:" + file["path"]
      end
    end
end
