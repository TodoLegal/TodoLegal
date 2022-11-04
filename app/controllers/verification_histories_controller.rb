class VerificationHistoriesController < ApplicationController
  before_action :set_verification_history, only: %i[ show edit update destroy ]

  # GET /verification_histories or /verification_histories.json
  def index
    @verification_histories = VerificationHistory.all
  end

  # GET /verification_histories/1 or /verification_histories/1.json
  def show
  end

  # GET /verification_histories/new
  def new
    @verification_history = VerificationHistory.new
  end

  # GET /verification_histories/1/edit
  def edit
  end

  # POST /verification_histories or /verification_histories.json
  def create
    @verification_history = VerificationHistory.new(verification_history_params)

    respond_to do |format|
      if @verification_history.save
        format.html { redirect_to @verification_history, notice: "Verification history was successfully created." }
        format.json { render :show, status: :created, location: @verification_history }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @verification_history.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /verification_histories/1 or /verification_histories/1.json
  def update
    respond_to do |format|
      if @verification_history.update(verification_history_params)
        format.html { redirect_to @verification_history, notice: "Verification history was successfully updated." }
        format.json { render :show, status: :ok, location: @verification_history }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @verification_history.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /verification_histories/1 or /verification_histories/1.json
  def destroy
    @verification_history.destroy
    respond_to do |format|
      format.html { redirect_to verification_histories_url, notice: "Verification history was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_verification_history
      @verification_history = VerificationHistory.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def verification_history_params
      params.require(:verification_history).permit(:datapoint_id, :document_id, :user_id, :is_verified, :verification_dt, :comments, :is_active)
    end
end
