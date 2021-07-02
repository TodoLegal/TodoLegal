class AlternativeTagNamesController < ApplicationController
  before_action :set_alternative_tag_name, only: %i[ show edit update destroy ]
  before_action :authenticate_editor!, only: [:index, :new, :edit, :create, :update, :destroy]

  # GET /alternative_tag_names or /alternative_tag_names.json
  def index
    @alternative_tag_names = AlternativeTagName.all
  end

  # GET /alternative_tag_names/1 or /alternative_tag_names/1.json
  def show
  end

  # GET /alternative_tag_names/new
  def new
    @alternative_tag_name = AlternativeTagName.new
  end

  # GET /alternative_tag_names/1/edit
  def edit
  end

  # POST /alternative_tag_names or /alternative_tag_names.json
  def create
    @alternative_tag_name = AlternativeTagName.new(alternative_tag_name_params)

    respond_to do |format|
      if @alternative_tag_name.save
        format.html { redirect_to @alternative_tag_name, notice: "Alternative tag name was successfully created." }
        format.json { render :show, status: :created, location: @alternative_tag_name }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @alternative_tag_name.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /alternative_tag_names/1 or /alternative_tag_names/1.json
  def update
    respond_to do |format|
      if @alternative_tag_name.update(alternative_tag_name_params)
        format.html { redirect_to @alternative_tag_name, notice: "Alternative tag name was successfully updated." }
        format.json { render :show, status: :ok, location: @alternative_tag_name }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @alternative_tag_name.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /alternative_tag_names/1 or /alternative_tag_names/1.json
  def destroy
    @alternative_tag_name.destroy
    respond_to do |format|
      format.html { redirect_to alternative_tag_names_url, notice: "Alternative tag name was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_alternative_tag_name
      @alternative_tag_name = AlternativeTagName.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def alternative_tag_name_params
      params.require(:alternative_tag_name).permit(:tag_id, :alternative_name)
    end
end
