class TagsController < ApplicationController
  include ActionView::Helpers::NumberHelper
  require 'set'

  before_action :set_tag, only: [:show, :edit, :update, :destroy]
  before_action :authenticate_editor!, only: [:index, :new, :edit, :create, :update, :destroy]

  # GET /tags
  # GET /tags.json
  def index
    @tags = Tag.all
  end

  # GET /tags/1
  # GET /tags/1.json
  def show
    @query = params[:query]

    if @query
      if redirectOnSpecialCode @query
        return
      end
    end
    
    if @query
      @query = params[:query]
      @laws = @tag.laws.search_by_name(@query).with_pg_search_highlight.with_tags
      @stream = Article.where(law: @tag.laws).search_by_body_highlighted(@query).group_by(&:law_id)
      @result_count = @laws.size
      @articles_count = @stream.size
      legal_documents = Set[]

      # Cache user plan status once to avoid repeated Stripe API calls
      @user_plan_status = current_user ? return_user_plan_status(current_user) : "Basic"
      @user_is_premium = current_user && @user_plan_status != "Basic" && current_user.confirmed_at?

      # Preload article counts in a single query to avoid N+1
      law_ids = @laws.pluck(:id)
      @article_counts = Article.where(law_id: law_ids).group(:law_id).count

      @laws.each do |law|
        legal_documents.add(law.id)
      end
      
      @grouped_laws = []
      @stream.each do |grouped_law|
        law = {count: grouped_law[1].count, law: Law.find_by_id(grouped_law[0]), preview: ("<b>Artículo " + grouped_law[1].first.number + "</b> " + grouped_law[1].first.body[0,300] + "...").html_safe}
        law[:materia_names] = law[:law].materia_names
        @grouped_laws.push(law)
        @result_count += grouped_law[1].count
        legal_documents.add(grouped_law[0])
      end
      @grouped_laws = @grouped_laws.sort_by{|k|k[:count]}.reverse
      @legal_documents_count = legal_documents.size
      if @result_count == 1
        @result_info_text = number_with_delimiter(@result_count, :delimiter => ',').to_s + ' resultado encontrado en la materia ' + @tag.name
      else
        @result_info_text = number_with_delimiter(@result_count, :delimiter => ',').to_s + ' resultados encontrados en la materia ' + @tag.name
      end
      titles_result = number_with_delimiter(@laws.size, :delimiter => ',')
      if @laws.size == 1
        @titles_result_text = titles_result.to_s + ' resultado'
      else
        @titles_result_text = titles_result.to_s + ' resultados'
      end
      articles_result = number_with_delimiter(@result_count - @laws.size, :delimiter => ',')
      if @result_count == 1
        @articles_result_text = articles_result.to_s + ' resultado'
      else
        @articles_result_text = articles_result.to_s + ' resultados'
      end

      if current_user
        $tracker.track(current_user.id, 'Site Search', {
          'query' => @query,
          'location' => @tag.name,
          'location_type' => "Tag",
          'results' => titles_result + articles_result
        })
      end
    else
      @laws = @tag.laws
        .with_tags
        .left_joins(:articles)
        .group(:id)
        .order('COUNT(articles.id) DESC')
      @result_count = @laws.count.values.size
      
      # Cache user plan status once to avoid repeated Stripe API calls
      @user_plan_status = current_user ? return_user_plan_status(current_user) : "Basic"
      @user_is_premium = current_user && @user_plan_status != "Basic" && current_user.confirmed_at?

      # Preload article counts in a single query to avoid N+1
      law_ids = @laws.pluck(:id)
      @article_counts = Article.where(law_id: law_ids).group(:law_id).count
      
      if @result_count == 1
        @result_info_text = number_with_delimiter(@result_count, :delimiter => ',').to_s + ' ley'
      else
        @result_info_text = number_with_delimiter(@result_count, :delimiter => ',').to_s + ' leyes'
      end
    end
  end

  # GET /tags/new
  def new
    @tag = Tag.new
  end

  # GET /tags/1/edit
  def edit
  end

  # POST /tags
  # POST /tags.json
  def create
    @tag = Tag.new(tag_params)
    respond_to do |format|
      if @tag.save
        format.html { redirect_to @tag, notice: 'Tag was successfully created.' }
        format.json { render :show, status: :created, location: @tag }
      else
        format.html { render :new }
        format.json { render json: @tag.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /tags/1
  # PATCH/PUT /tags/1.json
  def update
    respond_to do |format|
      if @tag.update(tag_params)
        format.html { redirect_to @tag, notice: 'Tag was successfully updated.' }
        format.json { render :show, status: :ok, location: @tag }
      else
        format.html { render :edit }
        format.json { render json: @tag.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /tags/1
  # DELETE /tags/1.json
  def destroy
    @tag.destroy
    respond_to do |format|
      format.html { redirect_to tags_url, notice: 'Tag was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_tag
      @tag = Tag.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def tag_params
      params.require(:tag).permit(:name, :tag_type_id)
    end
end
