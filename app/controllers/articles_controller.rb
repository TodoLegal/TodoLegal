class ArticlesController < ApplicationController
  before_action :set_article, only: [:edit, :update]
  before_action :authenticate_editor_tl!, only: [:edit, :update]

  # GET /articles/1/edit
  def edit
  end

  # PATCH/PUT /articles/1
  # PATCH/PUT /articles/1.json
  def update
    respond_to do |format|
      if @article.update(article_params)
        format.html { redirect_to edit_law_path(@article.law, article_number: @article.number), notice: 'Article was successfully updated.' }
      else
        format.html { render :edit }
        format.json { render json: @article.errors, status: :unprocessable_entity }
      end
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_article
      @article = Article.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def article_params
      params.require(:article).permit(:number, :body, :position, :law_id)
    end
end
