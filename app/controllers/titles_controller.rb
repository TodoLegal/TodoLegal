class TitlesController < ApplicationController
  before_action :set_title, only: [:show, :edit, :update, :destroy]

  # GET /titles
  # GET /titles.json
  def index
    if !current_user
      redirect_to "/"
    end

    @titles = Title.all
  end

  # GET /titles/1
  # GET /titles/1.json
  def show
    if !current_user
      redirect_to "/"
    end
  end

  # GET /titles/new
  def new
    if !current_user
      redirect_to "/"
    end

    @title = Title.new
  end

  # GET /titles/1/edit
  def edit
    if !current_user
      redirect_to "/"
    end
  end

  # POST /titles
  # POST /titles.json
  def create
    if !current_user
      redirect_to "/"
    end

    @title = Title.new(title_params)

    respond_to do |format|
      if @title.save
        format.html { redirect_to @title, notice: 'Title was successfully created.' }
        format.json { render :show, status: :created, location: @title }
      else
        format.html { render :new }
        format.json { render json: @title.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /titles/1
  # PATCH/PUT /titles/1.json
  def update
    if !current_user
      redirect_to "/"
    end

    respond_to do |format|
      if @title.update(title_params)
        format.html { redirect_to @title, notice: 'Title was successfully updated.' }
        format.json { render :show, status: :ok, location: @title }
      else
        format.html { render :edit }
        format.json { render json: @title.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /titles/1
  # DELETE /titles/1.json
  def destroy
    if !current_user
      redirect_to "/"
    end
    
    @title.destroy
    respond_to do |format|
      format.html { redirect_to titles_url, notice: 'Title was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_title
      @title = Title.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def title_params
      params.require(:title).permit(:position, :name, :number, :law_id)
    end
end
