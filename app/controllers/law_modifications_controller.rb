class LawModificationsController < ApplicationController
  before_action :set_law_modification, only: [:show, :edit, :update, :destroy]
  before_action :authenticate_editor!, only: [:show, :new, :edit, :create, :update, :destroy]

  # GET /law_modifications/1
  # GET /law_modifications/1.json
  def show
  end

  # GET /law_modifications/new
  def new
    @law_modification = LawModification.new
  end

  # GET /law_modifications/1/edit
  def edit
  end

  # POST /law_modifications
  # POST /law_modifications.json
  def create
    redirect_url = params[:law_modification][:return_to]
    law_url = params[:law_modification][:law_url]
    modification_type = params[:law_modification][:modification_type]
    document_id = params[:law_modification][:document_id]
    
    current_document = Document.find(document_id)
    
    # Extract law ID from URL
    extracted_law_id = extract_law_id_from_url(law_url)
    
    if extracted_law_id.nil?
      error_msg = "No se pudo extraer el ID de la ley de la URL proporcionada"
      handle_error(error_msg, redirect_url, current_document)
      return
    end
    
    # Check if law exists
    related_law = Law.find_by(id: extracted_law_id)
    if related_law.nil?
      error_msg = "La ley de la URL no existe en la base de datos"
      handle_error(error_msg, redirect_url, current_document)
      return
    end
    
    @law_modification = LawModification.new(
      document: current_document,
      law: related_law,
      modification_type: modification_type,
      modification_date: Date.current
    )
    
    respond_to do |format|
      if @law_modification.save
        if redirect_url.present?
          flash.now[:notice] = 'Modificación de ley creada exitosamente'
          format.turbo_stream do
            render turbo_stream: [
              turbo_stream.replace(
                "document_relationships_section",
                partial: "documents/document_relationships",
                locals: { document: current_document }
              ),
              turbo_stream.replace(
                "autosave_flash_relationships",
                partial: "layouts/flash",
                locals: {
                  alert_origin: "relationships",
                  alert_type: "success",
                  remove_alert: "true",
                  fade_timeout: "3000"
                }
              )
            ]
          end
          format.html { redirect_to redirect_url, notice: 'Modificación de ley creada exitosamente.' }
        else
          flash.now[:notice] = 'Modificación de ley creada exitosamente'
          format.turbo_stream do
            render turbo_stream: [
              turbo_stream.replace(
                "document_relationships_section",
                partial: "documents/document_relationships",
                locals: { document: current_document }
              )
            ]
          end
          format.html { redirect_to edit_document_path(current_document), notice: 'Modificación de ley creada exitosamente.' }
        end
        format.json { render json: { status: 'success' }, status: :created }
      else
        error_msg = @law_modification.errors.full_messages.join(', ')
        handle_error(error_msg, redirect_url, current_document)
      end
    end
  end

  # PATCH/PUT /law_modifications/1
  # PATCH/PUT /law_modifications/1.json
  def update
    respond_to do |format|
      if @law_modification.update(law_modification_params)
        format.html { redirect_to @law_modification, notice: 'Law modification was successfully updated.' }
        format.json { render :show, status: :ok, location: @law_modification }
      else
        format.html { render :edit }
        format.json { render json: @law_modification.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /law_modifications/1
  # DELETE /law_modifications/1.json
  def destroy
    redirect_url = params[:return_to]
    current_document_id = params[:current_document_id]
    
    # Get the document for refreshing the view
    document = current_document_id ? Document.find(current_document_id) : @law_modification.document
    
    @law_modification.destroy
    
    respond_to do |format|
      if redirect_url.present? && document
        flash.now[:notice] = 'Modificación de ley eliminada exitosamente'
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace(
              "document_relationships_section",
              partial: "documents/document_relationships",
              locals: { document: document }
            ),
            turbo_stream.replace(
              "autosave_flash_relationships",
              partial: "layouts/flash",
              locals: {
                alert_origin: "relationships",
                alert_type: "success",
                remove_alert: "true",
                fade_timeout: "3000"
              }
            )
          ]
        end
        format.html { redirect_to redirect_url, notice: 'Modificación de ley eliminada exitosamente.' }
      else
        law = @law_modification.law
        flash.now[:notice] = 'Modificación de ley eliminada exitosamente'
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace(
              "document_relationships_section",
              partial: "documents/document_relationships",
              locals: { document: document }
            )
          ]
        end
        format.html { redirect_to edit_law_path(law), notice: 'Law modification was successfully destroyed.' }
      end
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_law_modification
      @law_modification = LawModification.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def law_modification_params
      params.require(:law_modification).permit(:law_id, :document_id, :modification_type, :modification_date, :details, :affected_articles, :return_to, :current_document_id, :law_url)
    end
    
    # Extract law ID from TodoLegal URL
    def extract_law_id_from_url(url)
      return nil if url.blank?
      
      # Handle different URL patterns:
      # https://todolegal.app/laws/123
      # https://todolegal.app/laws/123/edit
      # https://todolegal.app/laws/169-codigo-penal
      # https://todolegal.app/laws/169-codigo-penal/edit
      # /laws/123
      # /laws/123/edit
      # laws/123
      
      url_patterns = [
        %r{laws/(\d+)(?:-[^/]+)?(?:/edit)?/?$},  # Match laws/ID or laws/ID-slug or laws/ID/edit or laws/ID-slug/edit
        %r{/(\d+)(?:/edit)?/?$}                  # Fallback for just /ID
      ]
      
      url_patterns.each do |pattern|
        match = url.match(pattern)
        return match[1].to_i if match
      end
      
      nil
    end
    
    # Handle errors consistently
    def handle_error(error_msg, redirect_url, current_document)
      respond_to do |format|
        flash.now[:alert] = error_msg
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "autosave_flash_relationships",
            partial: "layouts/flash",
            locals: {
              alert_origin: "relationships",
              alert_type: "danger",
              remove_alert: "true",
              fade_timeout: "3000"
            }
          )
        end
        
        fallback_location = current_document ? edit_document_path(current_document) : root_path
        format.html { redirect_back(fallback_location: fallback_location, alert: error_msg) }
        format.json { render json: { error: error_msg }, status: :unprocessable_entity }
      end
    end
end
