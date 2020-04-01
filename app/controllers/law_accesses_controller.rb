class LawAccessesController < ApplicationController
  before_action :set_law_access, only: [:show, :edit, :update, :destroy]
  before_action :authenticate_admin!, only: [:index, :show, :new, :edit, :create, :update, :destroy]

  # GET /law_accesses
  # GET /law_accesses.json
  def index
    @law_accesses = LawAccess.all
  end

  # GET /law_accesses/1
  # GET /law_accesses/1.json
  def show
  end

  # GET /law_accesses/new
  def new
    @law_access = LawAccess.new
  end

  # GET /law_accesses/1/edit
  def edit
  end

  # POST /law_accesses
  # POST /law_accesses.json
  def create
    @law_access = LawAccess.new(law_access_params)

    respond_to do |format|
      if @law_access.save
        format.html { redirect_to @law_access, notice: 'Law access was successfully created.' }
        format.json { render :show, status: :created, location: @law_access }
      else
        format.html { render :new }
        format.json { render json: @law_access.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /law_accesses/1
  # PATCH/PUT /law_accesses/1.json
  def update
    respond_to do |format|
      if @law_access.update(law_access_params)
        format.html { redirect_to @law_access, notice: 'Law access was successfully updated.' }
        format.json { render :show, status: :ok, location: @law_access }
      else
        format.html { render :edit }
        format.json { render json: @law_access.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /law_accesses/1
  # DELETE /law_accesses/1.json
  def destroy
    @law_access.destroy
    respond_to do |format|
      format.html { redirect_to law_accesses_url, notice: 'Law access was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_law_access
      @law_access = LawAccess.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def law_access_params
      params.require(:law_access).permit(:name)
    end
end
