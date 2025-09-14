class DocumentRelationshipsController < ApplicationController
  before_action :set_document_relationship, only: [:show, :edit, :update, :destroy]
  before_action :authenticate_editor!, only: [:show, :new, :edit, :create, :update, :destroy]

  # GET /document_relationships/1
  # GET /document_relationships/1.json
  def show
  end

  # GET /document_relationships/new
  def new
    @document_relationship = DocumentRelationship.new
  end

  # GET /document_relationships/1/edit
  def edit
  end

  # POST /document_relationships
  # POST /document_relationships.json
  def create
    redirect_url = params[:document_relationship][:return_to]
    document_url = params[:document_relationship][:document_url]
    modification_type = params[:document_relationship][:modification_type]
    current_document_id = params[:document_relationship][:source_document_id] || params[:document_relationship][:target_document_id]
    
    current_document = Document.find(current_document_id)
    
    # Extract document ID from URL
    extracted_document_id = extract_document_id_from_url(document_url)
    
    if extracted_document_id.nil?
      error_msg = "No se pudo extraer el ID del documento de la URL proporcionada"
      handle_error(error_msg, redirect_url, current_document_id)
      return
    end
    
    # Check if document exists
    related_document = Document.find_by(id: extracted_document_id)
    if related_document.nil?
      error_msg = "El documento de la URL no existe en la base de datos"
      handle_error(error_msg, redirect_url, current_document_id)
      return
    end
    
    # Set up relationship based on modification type
    case modification_type
    when 'amended_by', 'repealed_by'
      # Current document is target, URL document is source
      @document_relationship = DocumentRelationship.new(
        source_document_id: extracted_document_id,
        target_document_id: current_document_id,
        modification_type: modification_type.gsub('ed_by', '') # 'amended_by' -> 'amend', 'repealed_by' -> 'repeal'
      )
    when 'amends', 'repeals'
      # Current document is source, URL document is target
      @document_relationship = DocumentRelationship.new(
        source_document_id: current_document_id,
        target_document_id: extracted_document_id,
        modification_type: modification_type.gsub('s', '') # 'amends' -> 'amend', 'repeals' -> 'repeal'
      )
    else
      error_msg = "Tipo de modificación no válido"
      handle_error(error_msg, redirect_url, current_document_id)
      return
    end

    respond_to do |format|
      if @document_relationship.save
        if redirect_url.present?
          flash.now[:notice] = 'Relación de documento creada exitosamente'
          format.turbo_stream do
            render turbo_stream: [
              turbo_stream.replace(
                "document_relationships_section", #element ID in the view
                partial: "documents/relationships/document_relationships_section",
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
          format.html { redirect_to edit_document_path(current_document, return_to: redirect_url), notice: 'Relación creada exitosamente.' }
        else
          flash.now[:notice] = 'Relación de documento creada exitosamente'
          format.turbo_stream do
            render turbo_stream: [
              turbo_stream.replace(
                "document_relationships_section", #element ID in the view
                partial: "documents/relationships/document_relationships_section",
                locals: { document: current_document }
              )
            ]
          end
          format.html { redirect_to edit_document_path(current_document), notice: 'Relación creada exitosamente.' }
        end
        format.json { render :show, status: :created, location: @document_relationship }
      else
        error_msg = @document_relationship.errors.full_messages.join(', ')
        handle_error(error_msg, redirect_url, current_document_id)
      end
    end
  end

  # PATCH/PUT /document_relationships/1
  # PATCH/PUT /document_relationships/1.json
  def update
    respond_to do |format|
      if @document_relationship.update(document_relationship_params)
        format.html { redirect_to @document_relationship, notice: 'Relación actualizada exitosamente.' }
        format.json { render :show, status: :ok, location: @document_relationship }
      else
        format.html { render :edit }
        format.json { render json: @document_relationship.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /document_relationships/1
  # DELETE /document_relationships/1.json
  def destroy
    redirect_url = params[:return_to]
    
    # Determine which document we're editing (could be source or target)
    current_document_id = params[:current_document_id]
    if current_document_id.blank?
      # Try to infer from the referer or use source document as fallback
      current_document_id = @document_relationship.source_document_id
    end
    
    document = Document.find(current_document_id)
    @document_relationship.destroy
    
    respond_to do |format|
      if redirect_url.present?
        flash.now[:notice] = 'Relación eliminada exitosamente'
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace(
              "document_relationships_section",
              partial: "documents/relationships/document_relationships_section",
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
        format.html { redirect_to edit_document_path(document, return_to: redirect_url), notice: 'Relación eliminada exitosamente.' }
      else
        flash.now[:notice] = 'Relación eliminada exitosamente'
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace(
              "document_relationships_section",
              partial: "documents/relationships/document_relationships_section",
              locals: { document: document }
            )
          ]
        end
        format.html { redirect_to edit_document_path(document), notice: 'Relación eliminada exitosamente.' }
      end
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_document_relationship
    @document_relationship = DocumentRelationship.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def document_relationship_params
    params.require(:document_relationship).permit(:source_document_id, :target_document_id, :modification_type, :details, :modification_date, :return_to, :document_url)
  end
  
  # Extract document ID from TodoLegal URL
  def extract_document_id_from_url(url)
    return nil if url.blank?
    
    # Handle different URL patterns:
    # https://todolegal.app/documents/123
    # https://todolegal.app/documents/123/edit
    # /documents/123
    # /documents/123/edit
    # documents/123
    
    url_patterns = [
      %r{documents/(\d+)(?:/edit)?/?$},  # Match documents/ID or documents/ID/edit
      %r{/(\d+)(?:/edit)?/?$}           # Fallback for just /ID
    ]
    
    url_patterns.each do |pattern|
      match = url.match(pattern)
      return match[1].to_i if match
    end
    
    nil
  end
  
  # Handle errors consistently
  def handle_error(error_msg, redirect_url, current_document_id = nil)
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
      
      fallback_location = current_document_id ? edit_document_path(current_document_id) : root_path
      format.html { redirect_back(fallback_location: fallback_location, alert: error_msg) }
      format.json { render json: { error: error_msg }, status: :unprocessable_entity }
    end
  end
end
