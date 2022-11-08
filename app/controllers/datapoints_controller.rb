class DatapointsController < ApplicationController
  before_action :set_datapoint, only: %i[ show edit update destroy ]

  # GET /datapoints or /datapoints.json
  def index
    @datapoints = Datapoint.all
  end

  # GET /datapoints/1 or /datapoints/1.json
  def show
  end

  # GET /datapoints/new
  def new
    @datapoint = Datapoint.new
  end

  # GET /datapoints/1/edit
  def edit
  end

  # POST /datapoints or /datapoints.json
  def create
    @datapoint = Datapoint.new(datapoint_params)

    respond_to do |format|
      if @datapoint.save
        format.html { redirect_to @datapoint, notice: "Datapoint was successfully created." }
        format.json { render :show, status: :created, location: @datapoint }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @datapoint.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /datapoints/1 or /datapoints/1.json
  def update
    respond_to do |format|
      if @datapoint.update(datapoint_params)
        format.html { redirect_to @datapoint, notice: "Datapoint was successfully updated." }
        format.json { render :show, status: :ok, location: @datapoint }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @datapoint.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /datapoints/1 or /datapoints/1.json
  def destroy
    @datapoint.destroy
    respond_to do |format|
      format.html { redirect_to datapoints_url, notice: "Datapoint was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_datapoint
      @datapoint = Datapoint.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def datapoint_params
      params.require(:datapoint).permit(:user_permission_id, :name, :priority)
    end
end
