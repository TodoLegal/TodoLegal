module LawsHelper
    def current_law_name
        @current_law = Law.find(params[:id])
        return @law.name
    end

    def all_document_count
        Law.count + Document.count
    end

    def current_law_article
        @articles = @current_law.articles.order(:position)
        
        if params[:query]
            @tokens = params[:query].scan(/\w+|\W/)
            if @tokens.first == '/'
              articles = []
              @tokens.each do |token|
                if is_number token
                  articles = token
                end
              end
              params[:articles] = articles
              params[:query] = nil
            end
        end

        if params[:articles] && params[:articles].size > 0
            article_body = nil
            article = @articles.where('number LIKE ?', "%#{params[:articles].first}%").first
            if article
                article_body = @articles.where('number LIKE ?', "%#{params[:articles].first}%").first.body
            end

            article_text =  @current_law.articles.first.body
            if article_body
                article_text = article_body
            end
            return "Artículo " + "#{params[:articles].first}. " + article_text
        else
            article_body =  @current_law&.articles&.first&.body
            return "Artículo 1. " + article_body
        end
        # if @article_number
        #     return @law.articles.where('number LIKE ?', "%#{@article_number}%").first
        # else
        #    return @current_law.articles.first.body
        # end
        # @current_law.articles.first.body
    end

    def get_next_article current_article
        next_article = current_article.law.articles.find_by(number: [" #{current_article.number.to_i + 1}", "#{current_article.number.to_i + 1}"])
        return next_article
    end
    
    def get_previous_article current_article
        #error: undefined method `law' for nil:NilClass
        previous_article = current_article.law.articles.find_by(number:  [" #{current_article.number.to_i - 1}", "#{current_article.number.to_i - 1}"])
        return previous_article
    end

end
