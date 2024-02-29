class IssuerDocumentTagsController < ApplicationController
    before_action :set_document_tag, only: [:show, :edit, :update, :destroy]
    before_action :authenticate_editor!, only: [:show, :new, :edit, :create, :update, :destroy]

    # GET /document_tags/1
    # GET /document_tags/1.json
    def show
    end
  
    # GET /issuer_document_tags/new
    def new
      @issuer_document_tag = IssuerDocumentTag.new
    end
  
    # GET /issuer_document_tags/1/edit
    def edit
    end

    # POST /issuer_document_tags
    # POST /issuer_document_tags.json
    def create
      redirect_url = params[:issuer_document_tag][:return_to]
      if document_tag_params[:tag_id].to_i != 0
        @issuer_document_tag = IssuerDocumentTag.new(document_id: document_tag_params[:document_id], tag_id: document_tag_params[:tag_id])
      else
        @tag_type = TagType.find_by(name: document_tag_params[:tag_type])
        @new_tag = Tag.create(name: document_tag_params[:tag_id], tag_type_id: @tag_type.id)
        @issuer_document_tag = IssuerDocumentTag.new(document_id: document_tag_params[:document_id], tag_id: @new_tag.id)
      end

      respond_to do |format|
        if @issuer_document_tag.save
          if redirect_url
            format.html { redirect_to edit_document_path(@issuer_document_tag.document, return_to: redirect_url, datapoint_type: "tag" ), notice: 'Se ha añadido el tag exitosamente.' }
          else
            format.html { redirect_to edit_document_path(@issuer_document_tag.document), notice: 'Se ha añadido el tag exitosamente.' }
          end
          format.json { render :show, status: :created, location: @issuer_document_tag.document }
        else
          format.html { render :new }
          format.json { render json: @issuer_document_tag.errors, status: :unprocessable_entity }
        end
      end
    end

    # PATCH/PUT /issuer_document_tags/1
    # PATCH/PUT /issuer_document_tags/1.json
    def update
      respond_to do |format|
        if @issuer_document_tag.update(document_tag_params)
          format.html { redirect_to @issuer_document_tag, notice: 'Se ha actualizado la materia exitosamente.' }
          format.json { render :show, status: :ok, location: @issuer_document_tag }
        else
          format.html { render :edit }
          format.json { render json: @issuer_document_tag.errors, status: :unprocessable_entity }
        end
      end
    end
  
    # DELETE /issuer_document_tags/1
    # DELETE /issuer_document_tags/1.json
    def destroy
      redirect_url = params[:return_to]
      document = @issuer_document_tag.document
      @issuer_document_tag.destroy
      respond_to do |format|
        if redirect_url
          format.html { redirect_to edit_document_path(document, return_to: redirect_url, datapoint_type: "tag" ), notice: 'Se ha eliminado el tag exitosamente.' }
        else
          format.html { redirect_to edit_document_path(document), notice: 'Se ha eliminado el tag exitosamente.' }
        end
        format.json { head :no_content }
      end
    end

    private
      # Use callbacks to share common setup or constraints between actions.
      def set_document_tag
        @issuer_document_tag = IssuerDocumentTag.find(params[:id])
      end

      # Never trust parameters from the scary internet, only allow the white list through.
      def document_tag_params
        params.require(:issuer_document_tag).permit(:document_id, :tag_id, :tag_type, :return_to)
      end
end
