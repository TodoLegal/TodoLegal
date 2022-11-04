class TagTypesController < ApplicationController
  before_action :set_tag_type, only: [:show, :edit, :update, :destroy]
  before_action :authenticate_admin!, only: [:index, :show, :new, :edit, :create, :update, :destroy]

  # GET /tag_types
  # GET /tag_types.json
  def index
    @tag_types = TagType.all
  end

  # GET /tag_types/1
  # GET /tag_types/1.json
  def show
  end

  # GET /tag_types/new
  def new
    @tag_type = TagType.new
  end

  # GET /tag_types/1/edit
  def edit
  end

  # POST /tag_types
  # POST /tag_types.json
  def create
    @tag_type = TagType.new(tag_type_params)
    respond_to do |format|
      if @tag_type.save
        format.html { redirect_to @tag_type, notice: 'Tag type was successfully created.' }
        format.json { render :show, status: :created, location: @tag_type }
      else
        format.html { render :new }
        format.json { render json: @tag_type.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /tag_types/1
  # PATCH/PUT /tag_types/1.json
  def update
    respond_to do |format|
      if @tag_type.update(tag_type_params)
        format.html { redirect_to @tag_type, notice: 'Tag type was successfully updated.' }
        format.json { render :show, status: :ok, location: @tag_type }
      else
        format.html { render :edit }
        format.json { render json: @tag_type.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /tag_types/1
  # DELETE /tag_types/1.json
  def destroy
    @tag_type.destroy
    respond_to do |format|
      format.html { redirect_to tag_types_url, notice: 'Tag type was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_tag_type
      @tag_type = TagType.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def tag_type_params
      params.require(:tag_type).permit(:name)
    end
end
