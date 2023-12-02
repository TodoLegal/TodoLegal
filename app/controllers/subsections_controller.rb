class SubsectionsController < ApplicationController
  before_action :set_subsection, only: [:edit, :update]
  before_action :authenticate_editor!, only: [:edit, :update]

  # GET /subsections/1/edit
  def edit
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
