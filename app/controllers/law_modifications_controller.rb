class LawModificationsController < ApplicationController
  before_action :set_law_modification, only: [:show, :edit, :update, :destroy]
  before_action :authenticate_editor_tl!, only: [:show, :new, :edit, :create, :update, :destroy]

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
    @law_modification = LawModification.new(law_modification_params)
    respond_to do |format|
      if @law_modification.save
        format.html { redirect_to edit_law_path(@law_modification.law), notice: 'Law modification was successfully created.' }
        format.json { render :show, status: :created, location: @law_modification }
      else
        format.html { render :new }
        format.json { render json: @law_modification.errors, status: :unprocessable_entity }
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
    law = @law_modification.law
    @law_modification.destroy
    respond_to do |format|
      format.html { redirect_to edit_law_path(law), notice: 'Law modification was successfully destroyed.' }
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
      params.require(:law_modification).permit(:law_id, :name)
    end
end
