class DocumentTagsController < ApplicationController
    before_action :set_document_tag, only: [:show, :edit, :update, :destroy]
    before_action :authenticate_admin!, only: [:show, :new, :edit, :create, :update, :destroy]
  
    # GET /document_tags/1
    # GET /document_tags/1.json
    def show
    end
  
    # GET /document_tags/new
    def new
      @document_tag = DocumentTag.new
    end
  
    # GET /document_tags/1/edit
    def edit
    end
  
    # POST /document_tags
    # POST /document_tags.json
    def create
      @document_tag = DocumentTag.new(document_tag_params)
      respond_to do |format|
        if @document_tag.save
          format.html { redirect_to edit_document_path(@document_tag.document), notice: 'Se ha añadido a la materia exitosamente.' }
          format.json { render :show, status: :created, location: @document_tag.document }
        else
          format.html { render :new }
          format.json { render json: @document_tag.errors, status: :unprocessable_entity }
        end
      end
    end
  
    # PATCH/PUT /document_tags/1
    # PATCH/PUT /document_tags/1.json
    def update
      respond_to do |format|
        if @document_tag.update(document_tag_params)
          format.html { redirect_to @document_tag, notice: 'Se ha actualizado la materia exitosamente.' }
          format.json { render :show, status: :ok, location: @document_tag }
        else
          format.html { render :edit }
          format.json { render json: @document_tag.errors, status: :unprocessable_entity }
        end
      end
    end
  
    # DELETE /document_tags/1
    # DELETE /document_tags/1.json
    def destroy
      document = @document_tag.document
      @document_tag.destroy
      respond_to do |format|
        format.html { redirect_to edit_document_path(document), notice: 'Se ha quitado de la materia exitosamente.' }
        format.json { head :no_content }
      end
    end
  
    private
      # Use callbacks to share common setup or constraints between actions.
      def set_document_tag
        @document_tag = DocumentTag.find(params[:id])
      end
  
      # Never trust parameters from the scary internet, only allow the white list through.
      def document_tag_params
        params.require(:document_tag).permit(:document_id, :tag_id)
      end
  end
  