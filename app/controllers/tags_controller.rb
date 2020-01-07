class TagsController < ApplicationController
  include ActionView::Helpers::NumberHelper

  before_action :set_tag, only: [:show, :edit, :update, :destroy]

  # GET /tags
  # GET /tags.json
  def index
    if !current_user
      redirect_to "/"
    end

    @tags = Tag.all
  end

  # GET /tags/1
  # GET /tags/1.json
  def show
    @query = params[:query]
    if @query
      @query = params[:query]
      @laws = @tag.laws.search_by_name(@query).with_pg_search_highlight
      @stream = Article.where(law: @tag.laws).search_by_body(@query).group_by(&:law_id)
      @result_count = @laws.size
      @articles_count = @stream.size
      
      @grouped_laws = []
      @stream.each do |grouped_law|
        law = {count: grouped_law[1].count, law: Law.find_by_id(grouped_law[0])}
        @grouped_laws.push(law)
        @result_count += grouped_law[1].count
      end
      @grouped_laws = @grouped_laws.sort_by{|k|k[:count]}.reverse
      if @result_count == 1
        @result_info_text = number_with_delimiter(@result_count, :delimiter => ',').to_s + ' resultado encontrado en la materia ' + @tag.name + '.'
      else
        @result_info_text = number_with_delimiter(@result_count, :delimiter => ',').to_s + ' resultados encontrados en la materia ' + @tag.name + '.'
      end
    else
      @laws = @tag.laws
      @result_count = @laws.count
      if @result_count == 1
        @result_info_text = number_with_delimiter(@result_count, :delimiter => ',').to_s + ' resultado encontrado.'
      else
        @result_info_text = number_with_delimiter(@result_count, :delimiter => ',').to_s + ' resultados encontrados.'
      end
    end
  end

  # GET /tags/new
  def new
    if !current_user
      redirect_to "/"
    end

    @tag = Tag.new
  end

  # GET /tags/1/edit
  def edit
    if !current_user
      redirect_to "/"
    end
  end

  # POST /tags
  # POST /tags.json
  def create
    if !current_user
      redirect_to "/"
    end

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
    if !current_user
      redirect_to "/"
    end

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
    if !current_user
      redirect_to "/"
    end

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
