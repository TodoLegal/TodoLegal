module ArticlesHelper
  def get_next_article current_article
    next_article = current_article.law.articles.find_by(number: [" #{current_article.number.to_i + 1}", "#{current_article.number.to_i + 1}"])
    return next_article
  end

  def get_previous_article current_article
    previous_article = current_article.law.articles.find_by(number:  [" #{current_article.number.to_i - 1}", "#{current_article.number.to_i - 1}"])
    return previous_article
  end
end
