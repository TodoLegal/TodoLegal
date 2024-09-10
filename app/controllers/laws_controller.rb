class LawsController < ApplicationController
  layout 'law', only: [:show, :new, :edit]
  before_action :set_law, only: [:show, :edit, :update, :destroy, :insert_article]
  before_action :set_materias, only: [:show, :edit, :update, :destroy]
  before_action :authenticate_editor_tl!, only: [:index, :new, :edit, :create, :update, :destroy, :laws_hyperlinks]

  # GET /laws
  # GET /laws.json
  def index
    @laws = Law.all.order(:law_access_id)
  end

  # GET /laws/1
  # GET /laws/1.json
  def show
    #TODO: analyze why we did this validation and if we need to remove it 
    # if params[:id] != @law.friendly_url
    #   redirect_to "/?error=Invalid+law+name"
    # end
    @show_mercantil_related_podcast = LawTag.find_by(law: @law, tag: Tag.find_by_name("Mercantil")) != nil
    @show_laboral_related_podcast = LawTag.find_by(law: @law, tag: Tag.find_by_name("Laboral")) != nil
    @hyperlinks = @law.law_hyperlinks
    @hyperlinks = @law.law_hyperlinks
    @hyperlinks = @hyperlinks.to_a.sort_by { |hyperlink| hyperlink.article.number.strip.to_i } if @hyperlinks.present?
    get_raw_law
  end

  # GET /laws/new
  def new
    @law = Law.new
  end

  # GET /laws/1/edit
  def edit
    @active_tab = "general"
    @article_number = params[:article_number]
    if @article_number
      @article = @law.articles.find_by(number: ["#{@article_number}", " #{@article_number}"])
      @active_tab = "articles"
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

  def laws_hyperlinks 
    get_hyperlinks
    @hyperlinks.each do |hyperlink|
      law_hyperlink = LawHyperlink.find_or_initialize_by(
        law_id: hyperlink[:law].id,
        article_id: hyperlink[:article].id,
        hyperlink_text: hyperlink[:hyperlink_text]
      )
      law_hyperlink.linked_document_type = hyperlink[:document_type]
      law_hyperlink.linked_document_id = hyperlink[:document]&.id
      law_hyperlink.hyperlink = hyperlink[:hyperlink]
      law_hyperlink.save
    end

    status = params[:status]

    if params[:query].present?
      @law_hyperlinks = LawHyperlink.joins(:law).where("laws.name LIKE ?", "%#{params[:query]}%")
    else
      @law_hyperlinks = LawHyperlink.all
    end

    @law_hyperlinks = @law_hyperlinks.where(status: status) if status.present?

    # Paginate the results
    @law_hyperlinks = @law_hyperlinks.page params[:page]
  end

  def get_hyperlinks
    # Define a regular expression to match Markdown hyperlinks
    hyperlink_regex = /\[([^\]]*)\]\(([^\)]*)\)|<a href="([^"]*)">([^<]*)<\/a>/
    @hyperlinks = []
    # Iterate over all laws
    Law.all.each do |law|
      # Iterate over all articles of the law
      law.articles.each do |article|
        # Find all hyperlinks in the article body
        article.body.scan(hyperlink_regex) do |match|
          # Check which part of the match array contains the data
          if match[0] && match[1]
            hyperlink_text = match[0]
            hyperlink = match[1]
          else
            hyperlink_text = match[3]
            hyperlink = match[2]
          end
          # Extract the document from the hyperlink
          document = extract_document_from_url(hyperlink)
          # Determine the type of the document
          document_type = document.nil? ? nil : document.class.name
          # Store the law name, article number, hyperlink text, the hyperlink, the document, and the document type in the hyperlinks array
          @hyperlinks << { law: law, article: article, hyperlink_text: hyperlink_text, hyperlink: hyperlink, document: document, document_type: document_type }
        end
      end
    end
    # # Sort the hyperlinks by article number in ascending order
    # puts "=================================================================="
    # puts "Hyperlinks: " + @hyperlinks.to_s
    # puts "=================================================================="
    # @hyperlinks.sort_by! { |hyperlink| hyperlink[:article].number.strip.to_i }
  end

  def extract_document_from_url url
    matched_id = ""
    matched_document = nil
    if url.start_with?("../../laws/") || url.start_with?("../") || url.start_with?("https://todolegal.app/laws/") || url.start_with?("https://test.todolegal.app/laws/")
      match = url.match(/\/laws\/(\d+)/)
      matched_id =  match[1] if match
      matched_document = Law.find_by(id: matched_id)
    elsif url.start_with?(/\d+/)
      match = url.match(/^(\d+)/)
      matched_id =  match[1] if match
      matched_document = Law.find_by(id: matched_id)
    elsif url.start_with?("https://valid.todolegal.app/") || url.start_with?("https://test.valid.todolegal.app/")
      match = url.match(/\/(\d+)$/)
      matched_id =  match[1] if match
      matched_document = Document.find_by(id: matched_id)
    end
    matched_document
  end

  def automatic_update_hyperlink_status
    LawHyperlink.all.each do |law_hyperlink|
      if law_hyperlink.hyperlink.start_with?('https://valid.todolegal.app', 'https://test.valid.todolegal.app')
        id = law_hyperlink.hyperlink.split('/').last
        document = Document.find_by(id: id)
        
        if document
          law_hyperlink.update(status: 'activo')
        else
          law_hyperlink.update(status: 'inactivo')
        end
      end
    end
  
    redirect_to laws_hyperlinks_laws_path, notice: 'Se actualizó el Estado de los Enlaces de Valid.'
  end

  def update_hyperlink_status
    if params[:status]
      params[:status].each do |id, status|
        LawHyperlink.find(id).update(status: status)
      end
    end
    redirect_to laws_hyperlinks_laws_path, notice: 'Se actualizó el Estado de los Enlaces.'
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
      params.require(:law).permit(:name, :modifications, :creation_number, :revision_status, :status, :revision_date)
    end
end
