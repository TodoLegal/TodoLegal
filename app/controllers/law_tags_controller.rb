class LawTagsController < ApplicationController
  before_action :set_law_tag, only: [:show, :edit, :update, :destroy]

  # GET /law_tags
  # GET /law_tags.json
  def index
    if !current_user
      redirect_to "/"
    end

    @law_tags = LawTag.all
  end

  # GET /law_tags/1
  # GET /law_tags/1.json
  def show
    if !current_user
      redirect_to "/"
    end
  end

  # GET /law_tags/new
  def new
    if !current_user
      redirect_to "/"
    end

    @law_tag = LawTag.new
  end

  # GET /law_tags/1/edit
  def edit
  end

  # POST /law_tags
  # POST /law_tags.json
  def create
    if !current_user
      redirect_to "/"
    end

    @law_tag = LawTag.new(law_tag_params)

    respond_to do |format|
      if @law_tag.save
        format.html { redirect_to edit_law_path(@law_tag.law), notice: 'Law tag was successfully created.' }
        format.json { render :show, status: :created, location: @law_tag.law }
      else
        format.html { render :new }
        format.json { render json: @law_tag.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /law_tags/1
  # PATCH/PUT /law_tags/1.json
  def update
    if !current_user
      redirect_to "/"
    end

    respond_to do |format|
      if @law_tag.update(law_tag_params)
        format.html { redirect_to @law_tag, notice: 'Law tag was successfully updated.' }
        format.json { render :show, status: :ok, location: @law_tag }
      else
        format.html { render :edit }
        format.json { render json: @law_tag.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /law_tags/1
  # DELETE /law_tags/1.json
  def destroy
    if !current_user
      redirect_to "/"
    end
    
    law = @law_tag.law
    @law_tag.destroy
    respond_to do |format|
      format.html { redirect_to edit_law_path(law), notice: 'Law tag was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_law_tag
      @law_tag = LawTag.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def law_tag_params
      params.require(:law_tag).permit(:law_id, :tag_id)
    end
end
