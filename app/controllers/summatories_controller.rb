class SummatoriesController < ApplicationController
  before_action :set_summatory, only: %i[ show edit update destroy ]

  # GET /summatories or /summatories.json
  def index
    @summatories = Summatory.all
  end

  # GET /summatories/1 or /summatories/1.json
  def show
  end

  # GET /summatories/new
  def new
    @summatory = Summatory.new
  end

  # GET /summatories/1/edit
  def edit
  end

  # POST /summatories or /summatories.json
  def create
    @summatory = Summatory.new(summatory_params)

    respond_to do |format|
      if @summatory.save
        format.html { redirect_to summatory_url(@summatory), notice: "Summatory was successfully created." }
        format.json { render :show, status: :created, location: @summatory }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @summatory.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /summatories/1 or /summatories/1.json
  def update
    respond_to do |format|
      if @summatory.update(summatory_params)
        format.html { redirect_to summatory_url(@summatory), notice: "Summatory was successfully updated." }
        format.json { render :show, status: :ok, location: @summatory }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @summatory.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /summatories/1 or /summatories/1.json
  def destroy
    @summatory.destroy!

    respond_to do |format|
      format.html { redirect_to summatories_url, notice: "Summatory was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_summatory
      @summatory = Summatory.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def summatory_params
      params.require(:summatory).permit(:count_sum)
    end
end
