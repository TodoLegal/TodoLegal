class LawsController < ApplicationController
  before_action :set_law, only: [:show, :edit, :update, :destroy]
  layout 'law'

  # GET /laws
  # GET /laws.json
  def index
    @laws = Law.all
  end

  # GET /laws/1
  # GET /laws/1.json
  def show
    @stream = []
    @index_items = []
    @highlight_enabled = false
    @query = ""
    @articles_count = 0
    if params[:query] && params[:query] != ""
      @highlight_enabled = true
      @query = params[:query]
      @stream = @law.articles.search_by_body(params[:query]).with_pg_search_highlight
      @articles_count = @stream.size
    else
      i = 0
      title_iterator = 0
      chapter_iterator = 0
      article_iterator = 0

      @titles = @law.titles.order(:position)
      @chapters = @law.chapters.order(:position)
      @articles = @law.articles.order(:position)

      @articles_count = @articles.count

      stream_size = @titles.size + @chapters.size + @articles.size
      while i < stream_size
        if title_iterator < @titles.size && chapter_iterator < @chapters.size && article_iterator < @articles.size && @titles[title_iterator].position < @chapters[chapter_iterator].position && @titles[title_iterator].position < @articles[article_iterator].position
          @stream.push @titles[title_iterator]
          @index_items.push @titles[title_iterator]
          title_iterator+=1
        elsif chapter_iterator < @chapters.size && @chapters[chapter_iterator].position < @articles[article_iterator].position
          @stream.push @chapters[chapter_iterator]
          @index_items.push @chapters[chapter_iterator]
          chapter_iterator+=1
        else
          @stream.push @articles[article_iterator]
          article_iterator+=1
        end
        i+=1
      end
    end
  end

  # GET /laws/new
  def new
    @law = Law.new
  end

  # GET /laws/1/edit
  def edit
    @law_materias = []
    materia_tag_type = TagType.find_by_name("materia")
    @all_materias = Tag.where(tag_type: materia_tag_type)
    @law_materias = LawTag.where(law_id: @law.id, tag_id: @all_materias)

    creacion_tag_type = TagType.find_by_name("creacion")
    @all_creacions = Tag.where(tag_type: creacion_tag_type)
    @law_creacions = LawTag.where(law_id: @law.id, tag_id: @all_creacions)
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

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_law
      @law = Law.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def law_params
      params.require(:law).permit(:name, :modifications)
    end
end
