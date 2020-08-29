class SubsectionsController < ApplicationController
  before_action :set_subsection, only: [:show, :edit, :update, :destroy]
  before_action :authenticate_editor!, only: [:index, :show, :new, :edit, :create, :update, :destroy]

  # GET /subsections
  # GET /subsections.json
  def index
    @subsections = Subsection.all
  end

  # GET /subsections/1
  # GET /subsections/1.json
  def show
  end

  # GET /subsections/new
  def new
    @subsection = Subsection.new
  end

  # GET /subsections/1/edit
  def edit
  end

  # POST /subsections
  # POST /subsections.json
  def create
    @subsection = Subsection.new(subsection_params)
    respond_to do |format|
      if @subsection.save
        format.html { redirect_to @subsection, notice: 'Subsection was successfully created.' }
        format.json { render :show, status: :created, location: @subsection }
      else
        format.html { render :new }
        format.json { render json: @subsection.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /subsections/1
  # PATCH/PUT /subsections/1.json
  def update
    respond_to do |format|
      if @subsection.update(subsection_params)
        format.html { redirect_to @subsection, notice: 'Subsection was successfully updated.' }
        format.json { render :show, status: :ok, location: @subsection }
      else
        format.html { render :edit }
        format.json { render json: @subsection.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /subsections/1
  # DELETE /subsections/1.json
  def destroy
    @subsection.destroy
    respond_to do |format|
      format.html { redirect_to subsections_url, notice: 'Subsection was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_subsection
      @subsection = Subsection.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def subsection_params
      params.require(:subsection).permit(:number, :name, :position)
    end
end
