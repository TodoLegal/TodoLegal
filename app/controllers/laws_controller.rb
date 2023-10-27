class LawsController < ApplicationController
  layout 'law', only: [:show, :new, :edit]
  before_action :set_law, only: [:show, :edit, :update, :destroy, :insert_article]
  before_action :set_materias, only: [:show, :edit, :update, :destroy]
  before_action :authenticate_editor_tl!, only: [:index, :new, :edit, :create, :update, :destroy]

  # GET /laws
  # GET /laws.json
  def index
    @laws = Law.all.order(:law_access_id)
  end

  # GET /laws/1
  # GET /laws/1.json
  def show
    if params[:id] != @law.friendly_url
      redirect_to "/?error=Invalid+law+name"
    end
    @show_mercantil_related_podcast = LawTag.find_by(law: @law, tag: Tag.find_by_name("Mercantil")) != nil
    @show_laboral_related_podcast = LawTag.find_by(law: @law, tag: Tag.find_by_name("Laboral")) != nil
    get_raw_law
  end

  # GET /laws/new
  def new
    @law = Law.new
  end

  # GET /laws/1/edit
  def edit
    @article_number = params[:article_number]
    if @article_number
      @article = @law.articles.find_by(number: ["#{@article_number}", " #{@article_number}"])
    else
      @article = @law.articles.first
    end

    # @law_materias = []
    # materia_tag_type = TagType.find_by_name("materia")
    # @all_materias = Tag.where(tag_type: materia_tag_type)
    # @law_materias = LawTag.where(law_id: @law.id, tag_id: @all_materias)

    @law_modifications = @law.law_modifications
  end

  # POST /laws
  # POST /laws.json
  def create
    @law = Law.new(law_params)

    respond_to do |format|
      if @law.save
        format.html { redirect_to @law, notice: 'Law was successfully created.' }
        format.json { render :show, status: :created, location: @law }
      else
        format.html { render :new }
        format.json { render json: @law.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /laws/1
  # PATCH/PUT /laws/1.json
  def update
    respond_to do |format|
      if @law.update(law_params)
        format.html { redirect_to @law, notice: 'Law was successfully updated.' }
        format.json { render :show, status: :ok, location: @law }
      else
        format.html { render :edit }
        format.json { render json: @law.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /laws/1
  # DELETE /laws/1.json
  def destroy
    @law.destroy
    respond_to do |format|
      format.html { redirect_to laws_url, notice: 'Law was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  def insert_article
    @article_number = params[:article_number]
    if @article_number
      @previous_article = @law.articles.find_by(number: ["#{@article_number}", " #{@article_number}"])
      next_articles = @law.articles.where("position > ?", @previous_article.position).order(position: :asc)

      next_articles.each do | article |
        article.position = article.position + 1
        article.save
      end

      @previous_article_number = (@previous_article.number.to_i + 1).to_s
      new_article = Article.create(number: @previous_article_number, body: "", position: @previous_article.position + 1, law_id: @law.id)
      
      redirect_to edit_law_path(@law, article_number: new_article.number)
      
    else
      redirect_to edit_law_path(@law, article_number: @article_number)
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_law
      @law = Law.find(params[:id])
    end

    def set_materias
      @law_materias = []
      materia_tag_type = TagType.find_by_name("materia")
      @all_materias = Tag.where(tag_type: materia_tag_type)
      @law_materias = LawTag.where(law_id: @law.id, tag_id: @all_materias)

      @tag = Tag.find_by(id: @law_materias[0].tag_id)
      lawTags = LawTag.where(tag_id: @tag.id)
      
      @laws_array = []
      counter = 0
      while counter < lawTags.size
        law = Law.find_by(id: lawTags[counter].law_id)
        if law
          @laws_array[counter] = law
        end
        counter+=1
      end

    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def law_params
      params.require(:law).permit(:name, :modifications, :creation_number)
    end
end
